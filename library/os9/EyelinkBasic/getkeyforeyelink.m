function [key, tickcount]=getkeyforeyelink(el, tickcount)% USAGE: [key, tickcount]=getkeyforeyelink(el [, tickcount])%%		el: eyelink default values%		tickcount: supply time at which function was used last time% matlab version of eyelink supplied getkey() function% we can't call it getkey() as there is already a similar,% function in PsychToolbox% 02-06-01	fwc changed to accept el structure and tickcount value%				which should hold the time at which getkeyforeyelink was used%				last time.% 				key definitions are now set in 'initeyelinkdefaults.m' % excerpt from "exptsppt.h"% ******** KEY SCANNING ********/% some useful keys returned by getkey()                    */% These keys allow remote control of tracker during setup. */% on non-DOS platforms, you should produce these codes and */% all printable (0x20..0x7F) keys codes as well.           */% Return JUNK_KEY (not 0) if untranslatable key pressed.   */% TERMINATE_KEY can be to break out of EXPTSPPT loops.     */% Returns 0 if no key pressed          */% returns a single UINT16 integer code */% for both standard and extended keys  */% Standard keys == ascii value.        */% MSBy is set for extended codes       */key=0;if nargin < 1	error( 'USAGE: [key, tickcount]=getkeyforeyelink(el [, tickcount])' );endif nargin < 2	tickcount=0; % make sure we will run without a supplied tickcountendtt = getticks;if ~isempty( tickcount )	if tickcount==tt  % to prevent too rapid repeats of this function?		return;	endendtickcount = tt;% in original getkey() there was a test for cmd . (call to UserAbort()). % Obsolete within matlab environment as this stops matlab execution completely.% Here we provide an alternative (default is apple-esc).% you can change this by setting el.modifierkey en el.quitkey% specific quitkey defined in meyelinkinit.m file.[keyIsDown,secs,keyCode] = KbCheck;if keyCode(el.modifierkey) & keyCode( el.quitkey )	key=el.TERMINATE_KEY;	return;endavail = CharAvail;if avail==0 % no char available	return;endc=getchar;tickCount = 0;%c2=BITAND(c,255); % I don't think this is actually necessary on the mac					% but it may be so on a PCc2 = double(c);if c~=0	% fprintf( '%c\t%d\t%s\t%c\t%d\t%s\n', c, c, dec2hex(c), c2, c2, dec2hex(c2) );end% if(isprint(c&255)) return c&255;if c2>=hex2dec('20') & c2<=hex2dec('7F')	key=c2;	return;endswitch(c2)	case hex2dec('1E'),		key=el.CURS_UP;		return;	case hex2dec('1F'),		key=el.CURS_DOWN;		return;	case hex2dec('1C'),		key=el.CURS_LEFT;		return;	case hex2dec('1D'),		key=el.CURS_RIGHT;		return;	case { hex2dec('0D'), hex2dec('03') } % return and enter		key=el.ENTER_KEY;		return;	case { hex2dec('08'), hex2dec('1B') } % backspace and esc		key=el.ESC_KEY;		return;end% this bit of code from original getkey() function appears useless% at least on the macswitch(c)		case hex2dec('740B'),		key=el.PAGE_UP;		return;	case hex2dec('790C')		key=el.PAGE_DOWN;		return;end% as this is really testing for these two keys (or is this dependent on keyboard)?switch(c2)		case hex2dec('0B'),		key=el.PAGE_UP;		return;	case hex2dec('0C')		key=el.PAGE_DOWN;		return;endkey=el.JUNK_KEY;return;