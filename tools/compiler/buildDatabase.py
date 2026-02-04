from __future__ import annotations

import json
import re
import sys
import base64
import gzip
import uuid
from datetime import datetime, timezone
from pathlib import Path
from urllib import error as url_error
from urllib import parse as url_parse
from urllib import request as url_request


DEFAULT_REPOSITORY_BRANCH = "main"


def _format_value(value: object) -> str:
    try:
        return json.dumps(value, ensure_ascii=False)
    except TypeError:
        return repr(value)


def _check_url_exists(url: str, timeout_seconds: float = 8.0) -> bool:
    request = url_request.Request(url, method="HEAD")
    try:
        with url_request.urlopen(request, timeout=timeout_seconds) as response:
            return response.status < 400
    except url_error.HTTPError as exc:
        if exc.code in {405, 501}:
            try:
                with url_request.urlopen(url, timeout=timeout_seconds) as response:
                    return response.status < 400
            except Exception:
                return False
        return False
    except Exception:
        return False


def _normalize_repository_url(value: str) -> str:
    url = value.strip()
    if not url:
        return url
    if "://" not in url:
        url = f"https://{url}"
    return url


def _strip_query_and_fragment(url: str) -> str:
    parsed = url_parse.urlparse(url)
    return parsed._replace(query="", fragment="").geturl()


def _strip_file_name(url: str) -> str:
    parsed = url_parse.urlparse(url)
    path = parsed.path
    if path.endswith("/"):
        return url
    trimmed = "/".join(path.split("/")[:-1]) + "/"
    return parsed._replace(path=trimmed).geturl()


def _ensure_trailing_slash(url: str) -> str:
    return url if url.endswith("/") else f"{url}/"


def _build_raw_base(repository_url: str) -> str:
    clean = _strip_query_and_fragment(_normalize_repository_url(repository_url))

    if "raw.githubusercontent.com" in clean:
        return _ensure_trailing_slash(_strip_file_name(clean))

    if "github.com/" in clean:
        repo_path = clean.replace("https://", "").replace("http://", "")
        host_index = repo_path.find("github.com/")
        if host_index >= 0:
            repo_path = repo_path[host_index + len("github.com/") :]
        repo_path = repo_path.lstrip("/")

        branch = DEFAULT_REPOSITORY_BRANCH
        if "/tree/" in repo_path:
            parts = repo_path.split("/tree/")
            repo_path = parts[0]
            if len(parts) > 1:
                branch_part = parts[1]
                slash_index = branch_part.find("/")
                branch = branch_part[:slash_index] if slash_index >= 0 else branch_part

        if repo_path.endswith("/"):
            repo_path = repo_path[:-1]
        if repo_path.endswith(".git"):
            repo_path = repo_path[:-4]

        return f"https://raw.githubusercontent.com/{repo_path}/refs/heads/{branch}/"

    return _ensure_trailing_slash(_strip_file_name(clean))


def _get_config(config_path: Path) -> dict:
    try:
        with config_path.open("r", encoding="utf-8") as handle:
            config = json.load(handle)
    except (OSError, json.JSONDecodeError) as exc:
        raise RuntimeError(f"Failed to read config.json: {exc}") from exc

    repo_url = config.get("url")
    if not isinstance(repo_url, str) or not repo_url.strip():
        raise RuntimeError("config.json missing valid 'url' value.")

    return config


def main() -> None:
    repo_root = Path(__file__).resolve().parents[2]
    packages_root = repo_root / "packages"
    output_path = repo_root / "release" / "autogen_database.json"
    output_gzip_path = repo_root / "release" / "autogen_database.json.gz"
    version_path = repo_root / "release" / "autogen_version.txt"
    config_path = repo_root / "config.json"

    manifest_paths = sorted(packages_root.rglob("manifest.json"))
    if not manifest_paths:
        print("ERROR: No manifest.json files found under packages/")
        sys.exit(1)

    errors: list[str] = []
    manifests: list[dict] = []
    seen_ids: set[str] = set()
    try:
        config = _get_config(config_path)
    except RuntimeError as exc:
        print(f"ERROR: {exc}")
        sys.exit(1)
    repo_base = _build_raw_base(config["url"])
    title_max_length = config.get("titleMaxLength", 100)
    description_max_length = config.get("descriptionMaxLength", 500)
    images_max_count = config.get("imagesMaxCount", 8)
    image_max_bytes = config.get("imageMaxBytes", 1_048_576)

    for manifest_path in manifest_paths:
        package_label = str(manifest_path.relative_to(repo_root))
        rel_to_packages = manifest_path.relative_to(packages_root)
        username_from_path = rel_to_packages.parts[0] if rel_to_packages.parts else ""
        try:
            with manifest_path.open("r", encoding="utf-8") as handle:
                manifest = json.load(handle)
        except json.JSONDecodeError as exc:
            errors.append(
                f"ERROR: Invalid JSON syntax in {package_label} "
                f"(line {exc.lineno}, column {exc.colno})."
            )
            continue
        except OSError as exc:
            errors.append(f"ERROR: Failed to read {package_label}: {exc}")
            continue

        manifest_dir = manifest_path.parent

        id_path = manifest_path.parent / "autogen_id"
        package_id: str | None = None
        if id_path.exists():
            try:
                package_id = id_path.read_text(encoding="utf-8").strip()
            except OSError as exc:
                errors.append(
                    f"ERROR: Failed to read autogen_id ({exc}) in {package_label}."
                )
        else:
            package_id = str(uuid.uuid4())
            try:
                id_path.write_text(f"{package_id}\n", encoding="utf-8")
            except OSError as exc:
                errors.append(
                    f"ERROR: Failed to write autogen_id ({exc}) in {package_label}."
                )

        if not package_id:
            errors.append(f"ERROR: Missing or empty autogen_id in {package_label}.")
        else:
            if package_id in seen_ids:
                errors.append(
                    "ERROR: Duplicate id "
                    f"({ _format_value(package_id) }) in {package_label}."
                )
            seen_ids.add(package_id)

        thumbnail = manifest.get("thumbnail")
        if not isinstance(thumbnail, str) or not thumbnail.strip():
            errors.append(
                "ERROR: Missing or invalid thumbnail "
                f"({ _format_value(thumbnail) }) in {package_label}."
            )
        else:
            thumbnail_path = manifest_dir / thumbnail
            if not thumbnail_path.is_file():
                errors.append(
                    "ERROR: Thumbnail not found "
                    f"({ _format_value(thumbnail) }) in {package_label}."
                )
            else:
                try:
                    thumbnail_size = thumbnail_path.stat().st_size
                    if thumbnail_size > image_max_bytes:
                        errors.append(
                            "ERROR: Thumbnail exceeds max size "
                            f"(bytes={thumbnail_size}, limit={image_max_bytes}) "
                            f"({ _format_value(thumbnail) }) in {package_label}."
                        )
                except OSError as exc:
                    errors.append(
                        "ERROR: Failed to stat thumbnail "
                        f"({ _format_value(thumbnail) }) in {package_label}: {exc}"
                    )

        images = manifest.get("images")
        if not isinstance(images, list) or not images:
            errors.append(
                "ERROR: Missing or invalid images list "
                f"({ _format_value(images) }) in {package_label}."
            )
        else:
            if len(images) > images_max_count:
                errors.append(
                    "ERROR: Too many images "
                    f"(len={len(images)}, limit={images_max_count}) "
                    f"in {package_label}."
                )
            for image in images:
                if not isinstance(image, str) or not image.strip():
                    errors.append(
                        "ERROR: Invalid image entry "
                        f"({ _format_value(image) }) in {package_label}."
                    )
                    continue
                image_path = manifest_dir / image
                if not image_path.is_file():
                    errors.append(
                        "ERROR: Image not found "
                        f"({ _format_value(image) }) in {package_label}."
                    )
                else:
                    try:
                        image_size = image_path.stat().st_size
                        if image_size > image_max_bytes:
                            errors.append(
                                "ERROR: Image exceeds max size "
                                f"(bytes={image_size}, limit={image_max_bytes}) "
                                f"({ _format_value(image) }) in {package_label}."
                            )
                    except OSError as exc:
                        errors.append(
                            "ERROR: Failed to stat image "
                            f"({ _format_value(image) }) in {package_label}: {exc}"
                        )

        repository_url = manifest.get("repositoryURL")
        if not isinstance(repository_url, str) or not repository_url.strip():
            errors.append(
                "ERROR: Missing or invalid repositoryURL "
                f"({ _format_value(repository_url) }) in {package_label}."
            )
        else:
            parsed = url_parse.urlparse(repository_url)
            if parsed.scheme not in {"http", "https"}:
                errors.append(
                    "ERROR: repositoryURL must be http/https "
                    f"({ _format_value(repository_url) }) in {package_label}."
                )
            elif not parsed.netloc.endswith("github.com"):
                errors.append(
                    "ERROR: repositoryURL must point to github.com "
                    f"({ _format_value(repository_url) }) in {package_label}."
                )
            else:
                if not _check_url_exists(repository_url):
                    errors.append(
                        "ERROR: repositoryURL is not reachable "
                        f"({ _format_value(repository_url) }) in {package_label}."
                    )

        tags = manifest.get("tags")
        if not isinstance(tags, str) or not tags.strip():
            errors.append(
                "ERROR: Missing or empty tags "
                f"({ _format_value(tags) }) in {package_label}."
            )
        else:
            if " " in tags:
                errors.append(
                    "ERROR: Tags must not contain spaces "
                    f"({ _format_value(tags) }) in {package_label}."
                )
            else:
                invalid_tags = [
                    tag for tag in tags.split(",") if not re.fullmatch(r"[A-Za-z_]+", tag)
                ]
                if invalid_tags:
                    errors.append(
                        "ERROR: Invalid tag(s) "
                        f"({ _format_value(invalid_tags) }) in {package_label}."
                    )

        title_b64 = manifest.get("titleB64")
        if not isinstance(title_b64, str) or not title_b64.strip():
            errors.append(
                "ERROR: Missing or invalid titleB64 "
                f"({ _format_value(title_b64) }) in {package_label}."
            )
        else:
            try:
                decoded_title = base64.b64decode(title_b64, validate=True).decode(
                    "utf-8"
                )
                if len(decoded_title) > title_max_length:
                    errors.append(
                        "ERROR: title exceeds max chars "
                        f"(len={len(decoded_title)}, "
                        f"limit={title_max_length}) in {package_label}."
                    )
            except (ValueError, UnicodeDecodeError):
                errors.append(
                    "ERROR: Invalid base64 in titleB64 "
                    f"({ _format_value(title_b64) }) in {package_label}."
                )

        description_b64 = manifest.get("descriptionB64")
        if not isinstance(description_b64, str) or not description_b64.strip():
            errors.append(
                "ERROR: Missing or invalid descriptionB64 "
                f"({ _format_value(description_b64) }) in {package_label}."
            )
        else:
            try:
                decoded_description = base64.b64decode(
                    description_b64, validate=True
                ).decode("utf-8")
                if len(decoded_description) > description_max_length:
                    errors.append(
                        "ERROR: description exceeds max chars "
                        f"(len={len(decoded_description)}, "
                        f"limit={description_max_length}) in {package_label}."
                    )
            except (ValueError, UnicodeDecodeError):
                errors.append(
                    "ERROR: Invalid base64 in descriptionB64 "
                    f"({ _format_value(description_b64) }) in {package_label}."
                )

        app_major_version = manifest.get("appMajorVersion")
        if app_major_version not in {1, 2}:
            errors.append(
                "ERROR: appMajorVersion must be 1 or 2 "
                f"({ _format_value(app_major_version) }) in {package_label}."
            )

        updated_manifest = dict(manifest)
        updated_manifest["id"] = package_id
        updated_manifest["userName"] = username_from_path
        rel_package_dir = manifest_path.parent.relative_to(packages_root).as_posix()
        media_folder = updated_manifest.get("mediaFolder")
        folder = media_folder.strip() if isinstance(media_folder, str) else ""
        if not folder:
            folder = f"/{rel_package_dir}"
        elif not folder.startswith("/"):
            folder = f"/{folder}"
        updated_manifest.pop("mediaFolder", None)

        images_value = updated_manifest.get("images")
        if isinstance(images_value, list):
            normalized_images: list[str] = []
            for image in images_value:
                if isinstance(image, str):
                    image_name = image.strip().lstrip("/")
                    normalized_images.append(
                        f"{repo_base}packages{folder}/{image_name}"
                    )
                else:
                    normalized_images.append(image)
            updated_manifest["images"] = normalized_images

        thumbnail_value = updated_manifest.get("thumbnail")
        if isinstance(thumbnail_value, str) and thumbnail_value.strip():
            thumbnail_name = thumbnail_value.strip().lstrip("/")
            updated_manifest["thumbnail"] = (
                f"{repo_base}packages{folder}/{thumbnail_name}"
            )

        manifests.append(updated_manifest)

    if errors:
        for error in errors:
            print(error)
        sys.exit(1)

    output_path.parent.mkdir(parents=True, exist_ok=True)
    payload = {"packages": manifests}
    with output_path.open("w", encoding="utf-8") as handle:
        json.dump(payload, handle, indent=2, ensure_ascii=False)
        handle.write("\n")

    with gzip.open(output_gzip_path, "wt", encoding="utf-8") as handle:
        json.dump(payload, handle, indent=2, ensure_ascii=False)
        handle.write("\n")

    version_path.parent.mkdir(parents=True, exist_ok=True)
    timestamp = datetime.now(timezone.utc).astimezone().strftime("%Y-%m-%d %H:%M:%S %z")
    with version_path.open("w", encoding="utf-8") as handle:
        handle.write(f"{timestamp}\n")

    print("SUCCESS: Database and version files generated.")
    print(f"SUCCESS: {output_path}")
    print(f"SUCCESS: {output_gzip_path}")
    print(f"SUCCESS: {version_path}")


if __name__ == "__main__":
    main()
