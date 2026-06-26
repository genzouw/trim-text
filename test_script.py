import requests

def get_checkout_sha():
    url = "https://api.github.com/repos/actions/checkout/releases/latest"
    resp = requests.get(url).json()
    tag = resp['tag_name']
    url_tag = f"https://api.github.com/repos/actions/checkout/git/refs/tags/{tag}"
    resp_tag = requests.get(url_tag).json()
    return tag, resp_tag['object']['sha']

print(get_checkout_sha())
