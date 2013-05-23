/* ***** BEGIN LICENSE BLOCK *****
 * Version: MPL 1.1/GPL 2.0/LGPL 2.1
 *
 * The contents of this file are subject to the Mozilla Public License Version
 * 1.1 (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 * http://www.mozilla.org/MPL/
 *
 * Software distributed under the License is distributed on an "AS IS" basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
 * for the specific language governing rights and limitations under the
 * License.
 *
 * The Original Code is [Open Source Virtual Machine.].
 *
 * The Initial Developer of the Original Code is
 * Adobe System Incorporated.
 * Portions created by the Initial Developer are Copyright (C) 2004-2007
 * the Initial Developer. All Rights Reserved.
 *
 * Contributor(s):
 *   Adobe AS3 Team
 *
 * Alternatively, the contents of this file may be used under the terms of
 * either the GNU General Public License Version 2 or later (the "GPL"), or
 * the GNU Lesser General Public License Version 2.1 or later (the "LGPL"),
 * in which case the provisions of the GPL or the LGPL are applicable instead
 * of those above. If you wish to allow use of your version of this file only
 * under the terms of either the GPL or the LGPL, and not to allow others to
 * use your version of this file under the terms of the MPL, indicate your
 * decision by deleting the provisions above and replace them with the notice
 * and other provisions required by the GPL or the LGPL. If you do not delete
 * the provisions above, a recipient may use your version of this file under
 * the terms of any one of the MPL, the GPL or the LGPL.
 *
 * ***** END LICENSE BLOCK ***** */

package 
{
	// optionFlags values
	CONFIG const PCRE_CASELESS			= 0x00000001;
	CONFIG const PCRE_MULTILINE			= 0x00000002;
	CONFIG const PCRE_DOTALL			= 0x00000004;
	CONFIG const PCRE_EXTENDED			= 0x00000008;
	CONFIG const PCRE_ANCHORED			= 0x00000010;
	CONFIG const PCRE_DOLLAR_ENDONLY	= 0x00000020;
	CONFIG const PCRE_EXTRA				= 0x00000040;
	CONFIG const PCRE_NOTBOL			= 0x00000080;
	CONFIG const PCRE_NOTEOL			= 0x00000100;
	CONFIG const PCRE_UNGREEDY			= 0x00000200;
	CONFIG const PCRE_NOTEMPTY			= 0x00000400;
	CONFIG const PCRE_UTF8				= 0x00000800;
	CONFIG const PCRE_NO_AUTO_CAPTURE	= 0x00001000;
	CONFIG const PCRE_NO_UTF8_CHECK		= 0x00002000;
	CONFIG const PCRE_AUTO_CALLOUT		= 0x00004000;
	CONFIG const PCRE_PARTIAL			= 0x00008000;
	CONFIG const PCRE_DFA_SHORTEST		= 0x00010000;
	CONFIG const PCRE_DFA_RESTART		= 0x00020000;
	CONFIG const PCRE_FIRSTLINE			= 0x00040000;

	public dynamic class RegExp
	{
		[native(type="PCRE_GC*")]
		private var pcreInst:*;

		[native]
		nativeHookNS var global:Boolean;
		[native]
		nativeHookNS var hasNamedGroups:Boolean;

		nativeHookNS var optionFlags:int;
		nativeHookNS var lastIndex:int;
		nativeHookNS var source:String;

		// this is intended only to be used by constructHook implementations;
		// it constructs an object of the proper itraitsEnv, prototype, slots, etc
		// but does NOT run any ctor functions on it.
		private static native function _createInstance():RegExp;
		final private native function _initPCRE(pattern:String, optionFlags:int):void;
		
		// for result r:
		//
		// captureCount = r.length - 3
		// r[0] == substring that matched.
		// r[1...captureCount] are the captures
		// r[captureCount+1] == offset in string where match occurred
		// r[captureCount+2] == is subject
		//
		final private native function _pcre_exec(subject:String, lastIndex:int):Array;

		AS3 function replaceUsingFunction(subject:String, replaceFunctionAtom:*):String
		{
			var resultBuffer:String = "";
			var lastIndex:int;
			var subjectlen:int = subject.length;
			
			while (true)
			{
				var r:Array = this._pcre_exec(subject, lastIndex);
				if (!r)
				{
					// no more matches, must be done
					break;
				}
				var rlen:int = r.length;
				var matchIndex:int = r[rlen-2];
				var matchLen:int = r[0].length;
				
				resultBuffer += subject.substr(lastIndex, matchIndex-lastIndex);
				
				// function.apply requires a real Array so copy it into one
				resultBuffer += String(replaceFunctionAtom.apply(void(0), r));
				 
				var newLastIndex:int = matchIndex + matchLen;

				// prevents infinite looping in certain cases
				if (lastIndex == newLastIndex && this.global)
				{
					// Advance one character
					if (lastIndex < subjectlen)
					{
						resultBuffer += subject.substr(lastIndex, 1);
					}
					newLastIndex++;
				}

				lastIndex = newLastIndex;

				if (!this.global)
					break;
			} 

			// copy in stuff after last match
			if (lastIndex < subjectlen)
			{
				resultBuffer += subject.substr(lastIndex, subjectlen-lastIndex);
			}

			return resultBuffer;
		}

		private static function replaceUsingStringFunction(r:Array, replacement:String):String
		{
			// captureCount = r.length - 3
			// r[0] == substring that matched.
			// r[1...captureCount] are the captures
			// r[captureCount+1] == offset in string where match occurred
			// r[captureCount+2] == is subject

			var resultBuffer:String = "";
			var len:int = replacement.length;
			
			var captureCount:int = r.length - 3;
			var matchIndex:int = r[captureCount+1];
			var subject:String = r[captureCount+2];
			var matchLen:int = r[0].length;

			for (var i:int = 0; i < len; ++i) 
			{
				var cc:int = replacement.AS3::charCodeAt(i);
				if (cc == 36 /*'$'*/ && (i+1 < len)) 
				{
					i += 1;
					cc = replacement.AS3::charCodeAt(i);
					switch (cc) 
					{
						case 38: // '&':
							// Inserts the matched substring.
							resultBuffer += subject.AS3::substr(matchIndex, matchLen);
							break;
						case 96: // '`':
							// Inserts the portion of the string that precedes the matched substring.
							resultBuffer += subject.AS3::substr(0, matchIndex);
							break;
						case 39: // '\'':
							// 	Inserts the portion of the string that follows the matched substring.
							resultBuffer += subject.AS3::substr(matchIndex+matchLen);
							break;
						case 48: // '0':
						case 49: // '1':
						case 50: // '2':
						case 51: // '3':
						case 52: // '4':
						case 53: // '5':
						case 54: // '6':
						case 55: // '7':
						case 56: // '8':
						case 57: // '9':
							// 	Where n or nn are decimal digits, inserts the nth parenthesized submatch string, provided the first argument was a RegExp object.
							var idx:int = cc - 48;
							if (i+1 < len)
							{
								cc = replacement.AS3::charCodeAt(i+1);
								if (cc >= 48 && cc <= 57)
								{
									var tmp:int = idx*10 + (cc - 48);
									if (tmp <= captureCount) 
									{
										idx = tmp;
										i += 1;
									} 
									else 
									{
										// Gobbling up two digits would overflow the
										// capture count, so just use the one digit.
									}
									
								}
							}
							
							if (idx >= 1 && idx <= captureCount) 
							{
								resultBuffer += r[idx];
							} 
							else 
							{
								resultBuffer += String.AS3::fromCharCode(cc);
							}
							break;
						case 36: // '$':
						default:
							resultBuffer += String.AS3::fromCharCode(cc);
							break;
					}
				} 
				else 
				{
					resultBuffer += String.AS3::fromCharCode(cc);
				}
			}
			return resultBuffer;
		}

		AS3 function replaceUsingString(subject:String, replacement:String):String
		{
			var f:Function = function(...r:Array):String { return replaceUsingStringFunction(r, replacement); }
			return this.AS3::replaceUsingFunction(subject, f);
		}

		// {RO,DD,DE} properties of RegExp instances 
		public function get source():String { return this.nativeHookNS::source; }
		public function get global():Boolean { return this.nativeHookNS::global; }
		public function get ignoreCase():Boolean { return (this.nativeHookNS::optionFlags & CONFIG::PCRE_CASELESS) != 0; }
		public function get multiline():Boolean { return (this.nativeHookNS::optionFlags & CONFIG::PCRE_MULTILINE) != 0; }
		
		// {DD,DE} properties of RegExp instances 
		public function get lastIndex():int { return this.nativeHookNS::lastIndex; }
		public function set lastIndex(i:int):void { this.nativeHookNS::lastIndex = i; }

		// AS3 specific properties {RO,DD,DE}
		public function get dotall():Boolean { return (this.nativeHookNS::optionFlags & CONFIG::PCRE_DOTALL) != 0; }
		public function get extended():Boolean { return (this.nativeHookNS::optionFlags & CONFIG::PCRE_EXTENDED) != 0; }

		nativeHookNS static function callHook(...args):* 
		{ 
			if (args.length > 0) 
			{
				var arg0:* = args[0];
				var flags:* = (args.length > 1) ? args[1] : void(0);
				if ((arg0 is RegExp) && (flags === void(0)))
					return arg0;
			}
			
			return RegExp.nativeHookNS::constructHook.apply(args);
		}
		
		nativeHookNS static function constructHook(...args):* 
		{ 
			var a_patternAtom:* = (args.length>0) ? args[0] : void(0);
			var a_optionsAtom:* = (args.length>1) ? args[1] : void(0);

			if (a_patternAtom is RegExp) 
			{
				var a_patternRE:RegExp = a_patternAtom;
				// Pattern is a RegExp object
				if (a_optionsAtom !== void(0)) 
				{
					// ECMA 15.10.4.1 says to throw an error if flags specified
					throw makeError( TypeError, 1100 /*kRegExpFlagsArgumentError*/ );
				}
				
				// Return a clone of the RegExp object
				var a_newRE:RegExp = _createInstance();
				a_newRE.nativeHookNS::source			= a_patternRE.nativeHookNS::source;
				a_newRE.nativeHookNS::global			= a_patternRE.nativeHookNS::global;
				a_newRE.nativeHookNS::lastIndex			= a_patternRE.nativeHookNS::lastIndex;
				a_newRE.nativeHookNS::optionFlags		= a_patternRE.nativeHookNS::optionFlags;
				a_newRE.nativeHookNS::hasNamedGroups	= a_patternRE.nativeHookNS::hasNamedGroups;
				a_newRE._initPCRE(a_newRE.nativeHookNS::source, a_newRE.nativeHookNS::optionFlags);
				return a_newRE;
			}
			
			var a_pattern:String = (a_patternAtom !== void(0)) ? String(a_patternAtom) : "";
			var a_optionStr:String = (a_optionsAtom !== void(0)) ?  String(a_optionsAtom) : null;
			var a_optionFlags:int = CONFIG::PCRE_UTF8;
			var a_global:Boolean;
			var a_numSlashSeen:int;

			for (var i:int = 0; i < a_pattern.length; ++i)
			{
				// 47 == ascii '/'
				// 92 == ascii '\\'
				if (a_optionStr == null && a_pattern.charCodeAt(i) == 47 && (i == 0 || a_pattern.charCodeAt(i-1) != 92) && a_numSlashSeen++ > 0)
				{
					a_optionStr = a_pattern.substr(i);
					break;
				}
			}

			// check options
			if (a_optionStr != null)
			{		
				if (a_optionStr.indexOf("g") >= 0)	a_global = true;
				if (a_optionStr.indexOf("i") >= 0)	a_optionFlags |= CONFIG::PCRE_CASELESS;
				if (a_optionStr.indexOf("m") >= 0)	a_optionFlags |= CONFIG::PCRE_MULTILINE;
				if (a_optionStr.indexOf("s") >= 0)	a_optionFlags |= CONFIG::PCRE_DOTALL;
				if (a_optionStr.indexOf("x") >= 0)	a_optionFlags |= CONFIG::PCRE_EXTENDED;
			}
			
			var a_newRE:RegExp = _createInstance();
			a_newRE.nativeHookNS::source = a_pattern;
			a_newRE.nativeHookNS::global = a_global;
			a_newRE.nativeHookNS::optionFlags = a_optionFlags;
			a_newRE.nativeHookNS::hasNamedGroups = (a_pattern.indexOf("(?P<") >= 0);
			a_newRE._initPCRE(a_pattern, a_optionFlags);
			return a_newRE;
		}

		nativeHookNS static function makeProto():RegExp
		{
			var a_newRE:RegExp = _createInstance();
			return a_newRE;
		}

		nativeHookNS function callHook(...args:Array):* 
		{ 
			// not static: this call occurs when a regexp object is invoked directly as a function ala "/a|b/('dcab')"
			var argc:uint = uint(args.length);
			var inStr:String = argc > 0 ? String(args[0]) : "";
			return this.AS3::exec(inStr);
		}

		// RegExp.length = 1 per ES3
		
		// E262 {ReadOnly, DontDelete, DontEnum }
		public static const length:int = 1
		
		prototype.nativeHookNS::source = "(?:)";
		prototype.nativeHookNS::optionFlags = CONFIG::PCRE_UTF8;
		prototype._initPCRE("(?:)", CONFIG::PCRE_UTF8);

		prototype.toString = function():String
		{
			var r:RegExp = this; // TypeError if not
			var out:String = "/" + r.source + "/";
			if (r.global)		out += "g";
			if (r.ignoreCase)	out += "i";
			if (r.multiline)	out += "m";
			if (r.dotall)		out += "s";
			if (r.extended)		out += "x";
			return out;
		}

		prototype.exec = function(s="")
		{
			// arg not typed String, so that null and undefined convert
			// to "null" and "undefined", respectively
			var r:RegExp = this; // TypeError if not
			return r.AS3::exec(String(s));
		}

		AS3 function test(s:String=""):Boolean
		{
			return this.AS3::exec(s) != null;
		}
		
		prototype.test = function(s=""):Boolean
		{
			// arg not typed String, so that null and undefined convert
			// to "null" and "undefined", respectively
			var r:RegExp = this;
			return r.AS3::test(String(s));
		}

        // Dummy constructor function - This is neccessary so the compiler can do arg # checking for the ctor in strict mode
        // The code for the actual ctor is in RegExpClass::construct in the avmplus
        public function RegExp(pattern = void 0, options = void 0)
        {}

		AS3 function split(subject:String, limit:uint):Array
		{
			var out:Array = new Array();
			var startIndex:int = 0;
			var n:int = 0;
			var isEmptyRE:Boolean = nativeHookNS::source.length == 0;
			var subjectlen:int = subject.length;
			while (true)
			{
				var r:Array = this._pcre_exec(subject, startIndex);
				if (!r)
				{
					// no more matches, must be done
					break;
				}
				var rlen:int = r.length;
				var captureCount:int = rlen - 3;
				var matchIndex:int = r[captureCount+1];
				var matchLen:int = r[0].length;

				// [cn 11/22/04] when match is made, but is length 0 we've matched the empty
				//  position between characters.  Although we've "matched", its zero length so just break out.
				if (matchLen == 0) 
				{
					//matchLen = 0;
					matchIndex = startIndex + 1;
					if (!isEmptyRE)
					{
						// don't break if we're processing an empty regex - then we want to split the string into each character
						// so we want the loop to continue
						break;
					}
				}

				//[ed 8/10/04] don't go past end of string. not sure why pcre doesn't return null
				//for a match starting past the end.
				//[cn 12/3/04] because a regular expression which matches an empty position (space between characters)
				//  will match the empty position just past the last character.  This test is correct, though 
				//  it needs to come before we do any setProperties to avoid a bogus xtra result.
				var matchEnd:int = matchIndex + matchLen;
				if (matchEnd > subjectlen) 
				{
					startIndex = matchEnd;
					break;
				} 
				else 
				{
					out[n++] = subject.substr(startIndex, matchIndex - startIndex);
					if (n >= limit)
						break;

					for (var j:int = 1; j <= captureCount; j++) 
					{
						out[n++] = r[j];
						if (n >= limit)
							break;
					}

					// Advance past this match
					startIndex = matchEnd;				
				}
			}

			// If we found no match, or we did find a match and are still under limit, and there is a remainder left, add it 
			if (n < limit && startIndex <= subjectlen) 
			{
				out[n++] = subject.substr(startIndex, subjectlen - startIndex);
			}

			return out;
		}

		AS3 function exec(subject:String=""):*
		{
			var startIndex:int = this.nativeHookNS::global ? this.nativeHookNS::lastIndex : 0;
			
			var result:Array = null;
			var newLastIndex:int = 0;
			var r:Array = this._pcre_exec(subject, startIndex);
			if (r)
			{
				var rlen:int = r.length;
				var matchIndex:int = r[rlen-2];
				var matchLen:int = r[0].length;

				newLastIndex = matchIndex + matchLen;

				result = r;
				result.length -= 2;	// nuke the last two entries
				result.index = matchIndex;
				result.input = subject;
			}

			if (this.nativeHookNS::global)
			{
				this.nativeHookNS::lastIndex = newLastIndex;
			}

			return result;
			
		}
		
		AS3 function search(s:String):int
		{
			var r:Array = this._pcre_exec(s, 0);
			return r ? r[r.length-2] : -1;
		}

		AS3 function match(s:String):Array
		{
			if (!this.nativeHookNS::global)
			{
				return this.AS3::exec(s);
			}
			else
			{

				var oldLastIndex:int = this.nativeHookNS::lastIndex;
				this.nativeHookNS::lastIndex = 0;

				var a:Array = [];
				var matchArray:Array;
				while ((matchArray = this.AS3::exec(s)) != null)
				{
					a.push(matchArray[0]);
				}
				
				if (this.nativeHookNS::lastIndex == oldLastIndex)
				{
					this.nativeHookNS::lastIndex += 1;
				}
				
				return a;
			}
		}

		_hideproto(prototype);
	}
} 
