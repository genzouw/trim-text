import requests

def get_checkout_sha():
    url = "https://api.github.com/repos/actions/checkout/releases/latest"
    resp = requests.get(url, timeout=10)
    resp.raise_for_status()
    resp_json = resp.json()
    tag = resp_json['tag_name']
    url_tag = f"https://api.github.com/repos/actions/checkout/git/refs/tags/{tag}"
    resp_tag = requests.get(url_tag, timeout=10)
    resp_tag.raise_for_status()
    resp_tag_json = resp_tag.json()
    return tag, resp_tag_json['object']['sha']

print(get_checkout_sha())
