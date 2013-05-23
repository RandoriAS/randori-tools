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
	public final class String extends Object
	{
		// String.length = 1 per ES3
		// E262 {ReadOnly, DontDelete, DontEnum }
		public static const length:int = 1
		
		private static native function c2s(c:uint):String;
		
		private static function fcc(codes:Array):String
		{
		    var n:uint = codes.length
		    var s:String = ""
		    for (var i:uint=0; i < n; i++)
		        s += c2s(codes[i])
		    return s
		}
		
		AS3 static function fromCharCode(...codes):String
		{
		    return fcc(codes)
		}
		
		String.fromCharCode = function(...codes):String 
		{
			return fcc(codes)
		}

		// indexOf and other _ functions get early bound by MIR
		// native methods cannot have default arg values anymore, so wrap it

		final private native function _indexOf(s:String, i:Number):int;
		AS3 function indexOf(s:String="undefined", i:Number=0):int
		{
		    return _indexOf(s, i);
		}
		
		CONFIG::Full
		{
		    prototype.indexOf = function(s:String="undefined", i:Number=0):int
		    {
		        return String(this)._indexOf(s, i);
		    }
		}

		// lastIndexOf
		final private native function _lastIndexOf(s:String, i:Number):int;
		AS3 function lastIndexOf(s:String="undefined", i:Number=0x7FFFFFFF):int
		{
		    return _lastIndexOf(s, i);
		}
		
		CONFIG::Full
		{
    		prototype.lastIndexOf = function(s:String="undefined", i:Number=0x7fffffff):int 
    		{
    		    return String(this)._lastIndexOf(s, i); 
    		}
        }

		// charAt
		private static native function _charAt(str:String, i:Number):String;
		AS3 function charAt(i:Number=0):String
		{
		    return _charAt(this, i);
		}
		
		CONFIG::Full
		{
		    prototype.charAt = function(i:Number=0):String
		    {
		        return String._charAt(this, i);
		    }
		}

		// charCodeAt
		CONFIG::Full
		final private native function _charCodeAt(i:Number):Number;
		
		CONFIG::Full
		AS3 function charCodeAt(i:Number=0):Number
		{
		    return _charCodeAt(i);
		}
		
		CONFIG::Full
		{
		    prototype.charCodeAt = function(i:Number=0):Number
		    {
		        return String(this)._charCodeAt(i);
		    }
		}

		final private native function _localeCompare(other:String):int;
		AS3 function localeCompare(other:String=void(0)):int
		{
		    return _localeCompare(other);
		}
		
		CONFIG::Full
		{
		    prototype.localeCompare = function(other:String=void(0)):int
		    {
		        return String(this)._localeCompare(other);
		    }
		}

		// slice
		private static native function _slice(str:String, start:Number, end:Number):String;
		AS3 function slice(start:Number=0, end:Number=0x7fffffff):String
		{
		    return String._slice(this, start, end);
		}
		
		CONFIG::Full
		{
		    prototype.slice = function(start:Number=0, end:Number=0x7fffffff):String
		    {
		        return String._slice(this, start, end);
		    }
        }

		// substring
		CONFIG::Full
		private	static native function _substring(str:String, start:Number, end:Number):String;
		
		CONFIG::Full
		AS3 function substring(start:Number=0, end:Number=0x7fffffff):String
		{
		    return String._substring(this, start, end);
		}
		
		CONFIG::Full
		{
		    prototype.substring = function(start:Number=0, end:Number=0x7fffffff):String
		    {
		        return String._substring(this, start, end);
		    }
		}

		// substr
		private static native function _substr(str:String, start:Number, len:Number):String;
		AS3 function substr(start:Number=0, len:Number=0x7fffffff):String
		{
		    return String._substr(this, start, len);
		}
		
		CONFIG::Full
		{
		    prototype.substr = function(start:Number=0, len:Number=0x7fffffff):String
		    {
		        return String._substr(this, start, len);
		    }
		}

		CONFIG::Full
		AS3 function toLowerCase():String { return String._toLowerCase(this); }

		CONFIG::Full
		private static native function _toLowerCase(str:String):String;

		CONFIG::Full
		AS3 function toUpperCase():String { return String._toUpperCase(this); }

		CONFIG::Full
		private static native function _toUpperCase(str:String):String;

		// concat
		CONFIG::Full
		AS3 function concat(...args):String
		{
			var s:String = this
			for (var i:uint = 0, n:uint = args.length; i < n; i++)
				s = s + String(args[i])
			return s
		}

        CONFIG::Full
        {
		    prototype.concat = function(... args):String
		    {
			    // todo: use function.apply or array.join?
			    var s:String = String(this)
			    for (var i:uint = 0, n:uint = args.length; i < n; i++)
				    s = s + String(args[i])
			    return s
		    }
		}

		// match
		// P can be a RegEx or is coerced to a string (and then RegEx constructor is called)
		AS3 function match(p=void(0)):Array
		{
		    if (CONFIG::Full)
		    {
			    var re:RegExp;
			    if (p is RegExp)
			    {
				    re = p;
			    }
			    else
			    {
				    // ECMA-262 15.5.4.10
				    // If the argument is not a RegExp, invoke RegExp(exp)
				    re = new RegExp(String(p), "");
			    }
			    return re.AS3::match(this);
			}
			else
			{
			    // FIX: Need to implement without RegExp
			    return []
			}
		}
		
		CONFIG::Full
		{
		    prototype.match = function(p=void(0)):Array
		    {
			    return String(this).AS3::match(p);
		    }
        }
        
		// see Error.makeError
		internal function _replace(p:String, r:String):String { return this.AS3::replace(p, r); }
		
		// replace
		// p is a RegEx or string
		// repl is a function or coerced to a string
		AS3 function replace(pattern = void(0), replacementAtom = void(0)):String
		{
			var replaceFunction:* = null;
			var replacement:String = null;
			if (replacementAtom is Function) 
			{
				replaceFunction = replacementAtom;
			} 
			else 
			{
				replacement = String(replacementAtom);
			}

            if (CONFIG::Full)
            {
			    if (pattern is RegExp)
			    {
				    // RegExp mode
				    var reObj:RegExp = pattern;
				    if (replaceFunction != null) 
				    {
					    return reObj.AS3::replaceUsingFunction(this, replaceFunction);
				    } 
				    else 
				    {
					    return reObj.AS3::replaceUsingString(this, replacement);
				    }
			    } 
            }
            
			// String replace mode
			var searchString:String = String(pattern);
			var index:int = this.AS3::indexOf(searchString);
			if (index == -1) 
			{
				// Search string not found; return input unchanged.
				return this;
			}
			
			// Function.AS3::call only exists in Full builds...
            if (CONFIG::Full)
            {
				if (replaceFunction != null) 
				{
					// Invoke the replacement function to figure out the
					// replacement string
					replacement = String(replaceFunction.AS3::call(searchString, index, this));
				}
			}

			var newlen:int = this.length - searchString.length + replacement.length;

			var out:String = this.AS3::substr(0, index) + 
								replacement + 
								this.AS3::substr(index + searchString.length, this.length - searchString.length - index + 1);

			return out;
		}
		
		CONFIG::Full
		{
		    prototype.replace = function(p=void(0), repl=void(0)):String
		    {
			    var s:String = this;
			    return s.AS3::replace(p, repl);
		    }
		}

		// search
		// P can be a RegEx or is coerced to a string (and then RegEx constructor is called)
		AS3 function search(p=void(0)):int
		{
		    if (CONFIG::Full)
		    {
			    var re:RegExp;
			    if (p is RegExp)
			    {
				    re = p;
			    }
			    else
			    {
				    // ECMA-262 15.5.4.10
				    // If the argument is not a RegExp, invoke RegExp(exp)
				    re = new RegExp(String(p), "");
			    }
    			return re.AS3::search(this);
            }
            else
            {
                // FIX: Need to implement without RegExp
                return -1
            }
		}
		
		CONFIG::Full
		{
		    prototype.search = function(p=void(0)):int
		    {
			    var s:String = this;
			    return s.AS3::search(p);
		    }
		}
		
		AS3 function trim():String {
			return this;
		}

		// delim can be a RegEx or is coerced to a string (and then RegEx constructor is called)
		AS3 function split(delimAtom:* = void(0), limit:* = 0xffffffff):Array
		{
			if (limit === void(0))
				limit = 0xffffffff;	// if undefined is explicitly passed (rather than omitted), still do this
				
			var ulimit:uint = limit;
			if (ulimit == 0)
				return [];

			if (this.length == 0)
				return [ this ];

            if (CONFIG::Full)
            {
			    // handle RegExp case
			    if (delimAtom is RegExp)
			    {
				    var re:RegExp = delimAtom;
				    return re.AS3::split(this, ulimit);
			    }
			}

			var out:Array = []
			
			var ilen:int = this.length;
			var count:int = 0;
			var start:int = 0;

			var delim:String = String(delimAtom);
			var dlen:int = delim.length;
			if (dlen <= 0)
			{
				// delim is empty string, split on each char
				for (var i:int = 0; i < ilen && i < ulimit; i++)
				{
					out[count++] = this.AS3::substr(i, 1);
				}
				return out;
			}

			var w:int = 0;
			var dlast:Number = delim.AS3::charCodeAt(dlen-1);
			while (delim.AS3::charCodeAt(w) != dlast)
				w++;

			//loop1:
			var numSeg:uint = 0;
			for (var i:int = w; i < ilen; i++)
			{
				var continue_loop1:Boolean = false;
				var c:Number = this.AS3::charCodeAt(i);
				if (c == dlast)
				{
					var k:int = i-1;
					for (var j:int = dlen-2; j >= 0; j--, k--) 
					{
						if (this.AS3::charCodeAt(k) != delim.AS3::charCodeAt(j)) 
						{
							continue_loop1 = true;
							break;
						}
					}
					if (!continue_loop1) 
					{
						numSeg++;

						// if we have found more segments than 
						// the limit we can stop looking
						if (numSeg > ulimit)
							break;

						out[count++] = this.AS3::substr(start, k + 1 - start);
					
						start = i + 1;
						i += w;
					}
				}
			}

			// if numSeg is less than limit when we're done, add the rest of
			// the string to the last element of the array
			if (numSeg < ulimit )
			{
				out[count] = this.AS3::substr(start, ilen);
			}
			return out;
		}

        CONFIG::Full
		AS3 function toLocaleLowerCase():String
		{
			return this.AS3::toLowerCase();
		}

        CONFIG::Full
		AS3 function toLocaleUpperCase():String
		{
			return this.AS3::toUpperCase();
		}

		AS3 function toString():String
		{
		    return this
		}
		
		AS3 function valueOf():String
	    {
	        return this
	    }
		
		CONFIG::Full
		{
		    prototype.trim = function():String
		    {
		    	    return String(this).AS3::trim()
		    }
		
		    prototype.split = function(delim=void(0), limit=0xffffffff):Array
		    {
			    return String(this).AS3::split(delim, limit);
		    }

		    prototype.toLowerCase = prototype.toLocaleLowerCase = 
		    function():String
		    {
			    return String(this).AS3::toLowerCase()
		    }

		    prototype.toUpperCase = prototype.toLocaleUpperCase = 
		    function():String
		    {
			    return String(this).AS3::toUpperCase()
		    }
        
		    prototype.toString = function():String
		    {
			    if (this === prototype)
				    return ""

			    if (!(this is String))
				    throw makeError( TypeError, 1004 /*kInvokeOnIncompatibleObjectError*/, "String.prototype.toString" );

			    return this
		    }
    			
		    prototype.valueOf = function()
		    {
			    if (this === prototype)
				    return ""

			    if (!(this is String))
				    throw makeError( TypeError, 1004 /*kInvokeOnIncompatibleObjectError*/, "String.prototype.valueOf" );

			    return this
		    }
        }
        
        // Dummy constructor function - This is neccessary so the compiler can do arg # checking for the ctor in strict mode
        // The code for the actual ctor is in forth
        public function String(value = "")
        {}

		// E262 {DontEnum, DontDelete, ReadOnly}
		[forth(word="w_String_length")]
		public native function get length():int;
		
        _hideproto(prototype);
	}
}
