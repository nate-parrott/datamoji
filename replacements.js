$(function() {
	let transitionTextRecursive = (element, isAdding, textToAdd, durationPerKeystroke, callback) => {
		let curText = $(element).text();
		if (isAdding) {
			let isDone = curText === textToAdd;
			if (isDone) {
				callback();
			} else {
				let charToAdd = textToAdd[curText.length];
				$(element).text(curText + charToAdd);
				setTimeout(() => {
					transitionTextRecursive(element, true, textToAdd, durationPerKeystroke, callback);
				}, durationPerKeystroke);
			}
		} else {
			let isDone = curText === '';
			if (isDone) {
				setTimeout(() => {
					transitionTextRecursive(element, true, textToAdd, durationPerKeystroke, callback);
				}, durationPerKeystroke);
			} else {
				$(element).text(curText.slice(0, curText.length - 1));
				setTimeout(() => {
					transitionTextRecursive(element, false, textToAdd, durationPerKeystroke, callback);
				})
			}
		}
	}
	
	let transitionText = (element, text, callback) => {
		let charsToChange = $(element).text().length + text.length;
		let time = 600 / charsToChange;
		transitionTextRecursive(element, false, text, time, callback);
	}
	
	$("[data-replacements]").each((_, el) => {
		let replacements = $(el).attr('data-replacements').split('|');
		let i = 0;
		let delay = 2000;
		function change() {
			transitionText(el, replacements[(i++) % replacements.length], () => {
				setTimeout(change, delay);
			});
		}
		setTimeout(change, delay);
	})
});
