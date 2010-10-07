#!/bin/sh
if grep --silent '/usr/local/lib/rvm' $1
	then
	echo "rvm function already added."
else
	sed '$ a [[ -s "/usr/local/lib/rvm" ]] && . "/usr/local/lib/rvm"' --in-place="" $1
fi

# put this second so it picks up on the default version
if grep --silent 'ruby_version.rb' $1
	then
	echo "rvm prompt already added."
else
	sed '$ a PS1="\\`/usr/bin/ruby_version.rb\\` $PS1"' --in-place="" $1
fi
