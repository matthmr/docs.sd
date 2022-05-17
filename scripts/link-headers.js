console.log("[ .. ] Linking header names...");

const h2 = document.getElementsByTagName('h2');
const h3 = document.getElementsByTagName('h3');
const h4 = document.getElementsByTagName('h4');

const headers = [h2, h3, h4];

const LinkHeaders = () => {
	for (h of headers) {
		if (h[0] == undefined)
			continue;
		else {
			for (_h of h) {
				const hlink = _h.innerHTML.toLowerCase().replace(' ', '-');
				_h.setAttribute('id', hlink);
			}
		}
	}
};

LinkHeaders();
