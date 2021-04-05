source $stdenv/setup
set -euo pipefail
set -x

curl="curl            \
 --location           \
 --max-redirs 20      \
 --retry 2            \
 --disable-epsv       \
 --cookie-jar cookies \
 --insecure           \
 --speed-time 5       \
 -#                   \
 --fail               \
 $curlOpts            \
 $NIX_CURL_FLAGS"

if [ -n "${predictedURL:-}" ]; then
    echo "Trying to fetch with predicted URL: $predictedURL"
    $curl $predictedURL --output $out && exit 0
    echo "Predicted URL '$predictedURL' failed, querying registry"
fi

if [ -z "${index:-}" ]; then
    echo "No registry, defaulting to pypi"
    $index="https://pypi.org/simple"
fi

echo "Trying to fetch from registry $index"
$curl -H 'Accept: text/html' "${index}/${pname}" \
    | pup --color 'a json{}' \
    | jq --raw-output "to_entries[] | .value | select(.text==\"${file}\") | .href" \
    > url

# Gitlab urls will look like "${index}/files/${some-hash}/${pname}-${version}.tar.gz"
url=$(cat url)

if [[ ${url:0:1} == "/" ]] || [[ ${url:0:1} == "." ]]; then
    # JFrog urls look like "../../${pname}/${version}/${pname}-${version}.tar.gz"
    url="${index}/${pname}/${url}"
fi


$curl -k $url --output $out
