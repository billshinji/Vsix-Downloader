import urllib.request
import urllib.error
import argparse

def get_file(pn: str, en: str, version: str, target: str|None = None):
    target_query = f"?targetPlatform={target}" if target else ""
    target_name = f"@{target}" if target else ""
    targets = [(target_query, target_name)]
    if target:
        targets.append(("", ""))
    for target_query, target_name in targets:
        try:
            url = f"https://marketplace.visualstudio.com/_apis/public/gallery/publishers/{pn}/vsextensions/{en}/{version}/vspackage{target_query}"
            print(f"Downloading {url}")
            out_path = f"./{pn}.{en}-{version}{target_name}.vsix"
            with urllib.request.urlopen(url) as response, open(out_path, "wb") as out_file:
                out_file.write(response.read())
            print(f"Downloaded to {out_path}")
            break
        except urllib.error.HTTPError as e:
            print(f"Extension {pn}.{en} version {version} not found for target {target_name}. Error: {e}")
if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Download VSCode extension vsix package")
    parser.add_argument("-p", "--publisher", required=True, help="Publisher name")
    parser.add_argument("-e", "--extension", required=True, help="Extension name")
    parser.add_argument("-v", "--version", required=True, help="Extension version")
    parser.add_argument(
        "-t", "--target",
        help="Target platform (win32-x64, win32-arm64, linux-x64, linux-arm64, darwin-x64, darwin-arm64). 생략 시 모든 플랫폼용 다운로드 시도.",
        default=None
    )
    args = parser.parse_args()
    get_file(args.publisher, args.extension, args.version, args.target)

