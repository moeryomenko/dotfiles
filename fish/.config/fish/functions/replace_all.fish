function replace_all
	rg -l $argv[1] . | xargs sed -i "s/$argv[1]/$argv[2]/g"
end
