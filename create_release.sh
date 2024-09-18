version=$(grep -oP '(?<=version=").*(?=")' addons/godot-attributes/plugin.cfg)

git archive --format zip --output ./godot-attributes-v$version.zip main