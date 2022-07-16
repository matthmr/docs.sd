#!/usr/bin/awk -f

BEGIN {
	print header
	FS="<";
}

/<h.>.*?<\/h.>/ {
	str=$2;
	len=length($0);
	num=substr(str, 2, 1);

	if (num == 1) {
		print $0;
		next;
	}

	name=substr(str, 4, len - 4);
	_id=tolower(name);
	id=_id;
	gsub(" ", "-", id);

	printf "<h%d id='%s'>%s</h%d>\n", num, id, name, num;
	next;
}

{
	print $0;
}

END {
	print footer
}
