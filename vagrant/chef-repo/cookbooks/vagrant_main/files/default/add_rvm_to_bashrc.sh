#!/bin/sh
if grep --silent '[[ -s "/usr/local/lib/rvm" ]]' .bashrc
	then
	echo "rvm function already added."
else
	sed '$ a [[ -s "/usr/local/lib/rvm" ]] && . "/usr/local/lib/rvm"' --in-place="" .bashrc
fi

if grep --silent 'PS1="`/usr/bin/ruby_version.rb` $PS1"' .bashrc
	then
	echo "rvm prompt already added."
else
	sed '/[[ -s "/usr/local/lib/rvm" ]]/ i PS1="`/usr/bin/ruby_version.rb` $PS1"' --in-place="" .bashrc
fi
