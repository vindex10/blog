SCRIPT=$(realpath "$0")
SCRIPTPATH=$(dirname "$SCRIPT")
cd "$SCRIPTPATH"


function init() {
    mkdir -p dist/hugo
    pushd dist/hugo
    v=0.116.0
    name="hugo_extended_${v}_linux-amd64.tar.gz"
    wget "https://github.com/gohugoio/hugo/releases/download/v${v}/$name"
    tar -xvzf $name
    rm -rf $name
    popd
}

function hugo() {
    pushd src
    ../dist/hugo/hugo "$@"
    popd
}


cmd="$1";
shift;
$cmd "$@";
