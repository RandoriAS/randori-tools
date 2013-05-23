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
	public dynamic class Array extends Object
	{
	// ----------------------
	// data fields
	// ----------------------
		
		// Note that the Forth implementation of Array skips the normal "init to default values" code, and just leaves
		// all its fields at the default of zero (not null or undefined -- actual 0 bits).
		// Implementation relies on this, so be advised.
		
		[native(type="BoxVector*")]
		private var _denseArr:*;

		[native]
		private var _length:uint;

	// ----------------------
	// ctor
	// ----------------------
        // Dummy constructor function - This is neccessary so the compiler can do arg # checking for the ctor in strict mode
        // The code for the actual ctor is in forth
		public function Array(...args)
		{ }
		
	// ----------------------
	// Forth native words
	// ----------------------

        [forth(word="w_Array_private_delUintProperty")]
		final private native function _delUintProperty(u:uint):Boolean;

        [forth(word="w_Array_private_hasUintProperty")]
		final private native function _hasUintProperty(u:uint):Boolean;

	// ----------------------
	// Ordinary native methods
	// ----------------------
		final private native function _uintPropertyIsEnumerable(index:uint):Boolean;
		
	// ----------------------
	// pure AS3 methods
	// ----------------------

		// option flags for sort and sortOn
		public static const CASEINSENSITIVE:uint = 1;
		public static const DESCENDING:uint = 2;
		public static const UNIQUESORT:uint = 4;
		public static const RETURNINDEXEDARRAY:uint = 8;
		public static const NUMERIC:uint = 16;	
		
		override AS3 function hasOwnProperty(V=void(0)):Boolean
		{
			// E3 spec says that is V is an Object, we must call toString, not valueOf
			var sv = (V is Object) ? V.toString() : V;
			var uv:uint = sv;
			if (uv == sv)
				return this._hasUintProperty(uv);
				
			return super.AS3::hasOwnProperty(V);
		}

		override AS3 function propertyIsEnumerable(propertyName=void(0)):Boolean
		{
			var uv:uint = propertyName;
			if (uv == propertyName)
				return _uintPropertyIsEnumerable(uv);
			return super.AS3::propertyIsEnumerable(propertyName);
		}

		// E262 {DontEnum, DontDelete}
		public function get length():uint 
		{ 
			return _length; 
		}
		public function set length(newLength:*)
		{
			_set_length(newLength);
		}

		final private function _set_length(newLength:*)
		{
			var oldLength:uint = _length;
			var newLengthAsNumber:Number = newLength;
			var newLengthAsUint:uint = newLengthAsNumber;
			if (newLengthAsUint != newLengthAsNumber)
			{
				throw makeError( RangeError, 1005 /*kArrayIndexNotIntegerError*/, newLengthAsNumber );
			}

			for (var i:uint = newLengthAsUint; i < oldLength; ++i)
			{
				_delUintProperty(i);
			}
			_length = newLengthAsUint;
		}
		
		// Array.length = 1 per ES3
		public static const length:int = 1

		/**
		15.4.4.5 Array.prototype.join (separator)
		The elements of the array are converted to strings, and these strings are then concatenated, separated by
		occurrences of the separator. If no separator is provided, a single comma is used as the separator.
		The join method takes one argument, separator, and performs the following steps:
		1. Call the [[Get]] method of this object with argument "length".
		2. Call ToUint32(Result(1)).
		3. If separator is undefined, let separator be the single-character string ",".
		4. Call ToString(separator).
		5. If Result(2) is zero, return the empty string.
		6. Call the [[Get]] method of this object with argument "0".
		7. If Result(6) is undefined or null, use the empty string; otherwise, call ToString(Result(6)).
		8. Let R be Result(7).
		9. Let k be 1.
		10. If k equals Result(2), return R.
		11. Let S be a string value produced by concatenating R and Result(4).
		12. Call the [[Get]] method of this object with argument ToString(k).
		13. If Result(12) is undefined or null, use the empty string; otherwise, call ToString(Result(12)).
		14. Let R be a string value produced by concatenating S and Result(13).
		15. Increase k by 1.
		16. Go to step 10.
		*/

        CONFIG::Full
		private static function _join(o, sep):String
		{
			var s:String = (sep === undefined) ? "," : String(sep);
			var out:String = "";
			for (var i:uint = 0, n:uint=o.length; i < n; i++)
			{
				var x = o[i];
				if (x != null)
					out += x;
				if (i+1 < n)
					out += s;
			}
			return out;
		}
		
		CONFIG::Full
		AS3 function join(sep=void(0)):String
		{
			return _join(this, sep)
		}
		
		CONFIG::Full
		{
		    prototype.join = function(sep=void(0)):String
		    {
			    return _join(this, sep)
		    }
        }

		private static function _pop(o):*
		{
			if (!Object._isScriptObject(o))
				return void(0);
				
			var olen:uint = o.length;

			if (olen != 0)
			{
				--olen;
				var x = o[olen];
				delete o[olen];
				o.length = olen;
				return x;
			} 
			else
			{
				return void(0);
			}
		}

		AS3 function pop()
		{
			return _pop(this)
		}
		
		CONFIG::Full
		{
		    prototype.pop = function()
		    {
			    return _pop(this)
		    }
        }

		/**
		15.4.4.2 Array.prototype.toString ( )
		The result of calling this function is the same as if the built-in join method were invoked for this object with no
		argument.
		The toString function is not generic; it throws a TypeError exception if its this value is not an Array object.
		Therefore, it cannot be transferred to other kinds of objects for use as a method.
		*/
		
		CONFIG::Full
		{
		    prototype.toString = function():String
		    {
			    var a:Array = this  // TypeError if not compatible
			    return _join(a, ",");
		    }
        }
        
		/**
		15.4.4.3 Array.prototype.toLocaleString ( )
		The elements of the array are converted to strings using their toLocaleString methods, and these strings are
		then concatenated, separated by occurrences of a separator string that has been derived in an implementationdefined
		locale-specific way. The result of calling this function is intended to be analogous to the result of
		toString, except that the result of this function is intended to be locale-specific.
		The result is calculated as follows:
		1. Call the [[Get]] method of this object with argument "length".
		2. Call ToUint32(Result(1)).
		3. Let separator be the list-separator string appropriate for the host environment’s current locale (this is derived in
		an implementation-defined way).
		4. Call ToString(separator).
		5. If Result(2) is zero, return the empty string.
		6. Call the [[Get]] method of this object with argument "0".
		7. If Result(6) is undefined or null, use the empty string; otherwise, call ToObject(Result(6)).toLocaleString().
		8. Let R be Result(7).
		9. Let k be 1.
		10. If k equals Result(2), return R.
		11. Let S be a string value produced by concatenating R and Result(4).
		12. Call the [[Get]] method of this object with argument ToString(k).
		13. If Result(12) is undefined or null, use the empty string; otherwise, call ToObject(Result(12)).toLocaleString().
		14. Let R be a string value produced by concatenating S and Result(13).
		15. Increase k by 1.
		16. Go to step 10.
		The toLocaleString function is not generic; it throws a TypeError exception if its this value is not an Array
		object. Therefore, it cannot be transferred to other kinds of objects for use as a method.
		*/

        CONFIG::Full
        {
		    prototype.toLocaleString = function():String
		    {
			    var a:Array = this // TypeError if not compatible

			    var out:String = ""
			    for (var i:uint = 0, n:uint=a.length; i < n; i++)
			    {
				    var x = a[i]
				    if (x != null)
					    out += x.toLocaleString()
				    if (i+1 < n)
					    out += ","
			    }
			    return out
		    }
        }
        
		/**
		When the push method is called with zero or more arguments item1, item2, etc., the following steps are taken:
		1. Call the [[Get]] method of this object with argument "length".
		2. Let n be the result of calling ToUint32(Result(1)).
		3. Get the next argument in the argument list; if there are no more arguments, go to step 7.
		4. Call the [[Put]] method of this object with arguments ToString(n) and Result(3).
		5. Increase n by 1.
		6. Go to step 3.
		7. Call the [[Put]] method of this object with arguments "length" and n.
		8. Return n.
		The length property of the push method is 1.
		NOTE The push function is intentionally generic; it does not require that its this value be an Array object. Therefore it can be
		transferred to other kinds of objects for use as a method. Whether the push function can be applied successfully to a host object
		is implementation-dependent.
		*/
		private static function _push(o, args:Array):uint
		{
			var olen:uint = o.length;
			var argslen:uint = args.length;
			if (argslen == 1)
				o[olen++] = args[0]
			else
				for (var i:uint = 0; i < argslen; i++)
					o[olen++] = args[i];
			o.length = olen;
			return olen;
		}
		AS3 function push(...args):uint
		{
			return _push(this, args);
		}
		prototype.push = function(...args):uint
		{
			return _push(this, args);
		}

        CONFIG::Full
		private static function _reverse(o)
		{
			if (!Object._isScriptObject(o))
				return o;

			var i:uint = 0;
			var j:uint = o.length;
			if (j)
				j--;

			while (i < j) 
			{
				var front = o[i];
				var back = o[j];
				o[i++] = back;
				o[j--] = front;
			}
			return o;
		}
		
		CONFIG::Full
		AS3 function reverse():Array
		{
			return _reverse(this)  // return will cast to Array
		}
		
		CONFIG::Full
		{
		    prototype.reverse = function()
		    {
			    return _reverse(this)
		    }
		}

        CONFIG::Full
		private static function _concat(o, args):Array
		{
			var out:Array = new Array;
			
			if (o is Array)
			{
				var olen:uint = o._length;
				for (var i:uint = 0; i < olen; i++) 
				{
					out[i] = o[i];
				}
			}

			var argslen:uint = (args != null) ? args.length : 0;
			for (var i:uint = 0; i < argslen; i++) 
			{
				var x = args[i];
				if (x is Array) 
				{
					var len:uint = x._length;
					for (var j:uint = 0; j < len; j++) 
					{
						out._length = out.push(x[j]);
					}
				}
				else
				{
					out._length = out.push(x);
				}
			}

			return out;
		}
		
		CONFIG::Full
		AS3 function concat(...args):Array
		{
			return _concat(this, args)
		}
		
		CONFIG::Full
		{
		    prototype.concat = function(...args):Array
		    {
			    return _concat(this, args)
		    }
		}

		private static function _shift(o)
		{
			if (!Object._isScriptObject(o))
				return void(0);

			var olen:uint = o.length;
			if (olen == 0)
			{
				o.length = 0;	// ECMA-262 requires explicit set here
				return void(0);
			}
			else
			{
				// Get the 0th element to return
				var x = o[0];

				// Move all of the elements down
				for (var i:uint = 1; i < olen; i++) 
				{
					o[i-1] = o[i];
				}
				delete o[olen - 1];
				o.length = olen - 1;

				return x;
			}
		}
		AS3 function shift()
		{
			return _shift(this)
		}
		
		CONFIG::Full
		{
		    prototype.shift = function()
		    {
			    return _shift(this)
		    }
        }
        
		private static function _slice(o, A:Number, B:Number):Array
		{
			if (!Object._isScriptObject(o))
				return null;

			var olen:uint = o.length;

			// if a param is passed then the first one is A
			// if no params are passed then A = 0
			var a:uint = _clampIndex(A, olen);
			var b:uint = _clampIndex(B, olen);
			if (b < a)
				b = a;

			var out:Array = new Array(b-a);
			for (var i:uint = a, j:uint = 0; i < b; i++, j++) 
			{
				out[j] = o[i]
			}

			return out;
		}
		AS3 function slice(A:Number = 0, B:Number = 0xffffffff):Array
		{
			return _slice(this, A, B)
		}
		
		CONFIG::Full
		{
		    prototype.slice = function(A:Number = 0, B:Number = 0xffffffff):Array
		    {
			    return _slice(this, A, B)
		    }
        }
        
		/**
		15.4.4.13 Array.prototype.unshift ( [ item1 [ , item2 [ , … ] ] ] )
		The arguments are prepended to the start of the array, such that their order within the array is the same as the
		order in which they appear in the argument list.
		When the unshift method is called with zero or more arguments item1, item2, etc., the following steps are taken:
		1. Call the [[Get]] method of this object with argument "length".
		2. Call ToUint32(Result(1)).
		3. Compute the number of arguments.
		4. Let k be Result(2).
		5. If k is zero, go to step 15.
		6. Call ToString(k–1).
		7. Call ToString(k+Result(3)–1).
		8. If this object has a property named by Result(6), go to step 9; but if this object has no property named by
		Result(6), then go to step 12.
		9. Call the [[Get]] method of this object with argument Result(6).
		10. Call the [[Put]] method of this object with arguments Result(7) and Result(9).
		11. Go to step 13.
		12. Call the [[Delete]] method of this object with argument Result(7).
		13. Decrease k by 1.
		14. Go to step 5.
		15. Let k be 0.
		16. Get the next argument in the part of the argument list that starts with item1; if there are no more arguments, go
		to step 21.
		17. Call ToString(k).
		18. Call the [[Put]] method of this object with arguments Result(17) and Result(16).
		19. Increase k by 1.
		20. Go to step 16.
		21. Call the [[Put]] method of this object with arguments "length" and (Result(2)+Result(3)).
		22. Return (Result(2)+Result(3)).
		The length property of the unshift method is 1.
		NOTE The unshift function is intentionally generic; it does not require that its this value be an Array object. Therefore it can
		be transferred to other kinds of objects for use as a method. Whether the unshift function can be applied successfully to a
		host object is implementation-dependent.
		*/
		
		CONFIG::Full
		private static function _unshift(o, args):uint
		{
			var olen:uint = o.length;
			var argslen:uint = args.length;

			var k:uint;
			for (k = olen; k > 0; /*nothing*/)
			{
				k--;
				var d:uint = k + argslen;
				if (k in o)
					o[d] = o[k];
				else
					delete o[d];
			}

			for (var i:uint = 0; i < argslen; i++)
				o[k++] = args[i];

			olen += argslen;
			o.length = olen;
			return olen;
		}
		
		CONFIG::Full	
		AS3 function unshift(...args):uint
		{
			return _unshift(this, args);
		}
		
		CONFIG::Full
		{
		    prototype.unshift = function(...args):uint
		    {
			    return _unshift(this, args);
		    }
		}

		private static function _splice(o, args:Array):*
		{
			var argslen:uint = args.length;
			if (argslen == 0)
				return void(0);

			if (!Object._isScriptObject(o))
				return null;
			
			var olen:uint = o.length;
			var start:uint = _clampIndex(args[0], olen);
			var d_deleteCount:Number = argslen > 1 ? args[1] : (olen - start); 
			var deleteCount:uint = (d_deleteCount < 0) ? 0 : d_deleteCount;
			if (deleteCount > (olen - start)) 
			{
				deleteCount = olen - start;
			}
			var end:uint = start + deleteCount;

			// Copy out the elements we are going to remove
			var out:Array = new Array(deleteCount);
			for (var i:uint = 0; i < deleteCount; i++) 
			{
				out[i] = o[i + start];
			}

			var insertCount:uint = (argslen > 2) ? (argslen - 2) : 0;
			var l_shiftAmount:Number = insertCount - deleteCount; // Number because result could be negative
			var shiftAmount:uint;

			// delete items by shifting elements past end (of delete) by l_shiftAmount
			if (l_shiftAmount < 0) 
			{
				// Shift the remaining elements down
				shiftAmount = -l_shiftAmount;

				for (var i:uint = end; i < olen; i++) 
				{
					o[i - shiftAmount] = o[i];
				}
						
				// delete top elements here to match ECMAscript spec (generic object support)
				for (var i:uint = olen - shiftAmount; i < olen; i++) 
				{
					delete o[i];
				}
			} 
			else 
			{
				// Shift the remaining elements up. 
				shiftAmount = l_shiftAmount;

				for (var i:uint = olen; i > end; )  // Note: i is unsigned, can't check if --i >=0.
				{
					--i;
					o[i + shiftAmount] = o[i];
				}
			}

			// Add the items to insert
			for (var i:uint = 0; i < insertCount; i++) 
			{
				o[start+i] = args[i + 2];
			}

			// shrink array if shiftAmount is negative
			o.length = olen + l_shiftAmount;
				
			return out;
		}
		
		// splice with zero args returns undefined. All other cases return Array.
		AS3 function splice(...args):*
		{
			if (!args.length)
				return undefined;

			return _splice(this, args);
		}
		
		CONFIG::Full
		{
		    prototype.splice = function(...args):*
		    {
			    if (!args.length)
				    return undefined;

			    return _splice(this, args);
		    }
		}

		// thisAtom is object to process 
		// 1st arg of args is a function or a number
		// 2nd arg of args is a number 
		//
		// valid AS3 syntax:
		// sort()
		// sort(function object)
		// sort(number flags)
		// sort(function object, number flags)

		// This takes a args object because there is no way to distinguigh between sort()
		// and sort(undefined, 0) if we take default parameters.
		private static function _sort(thisAtom:*, args:*):*
		{
			if (!Object._isScriptObject(thisAtom))
				return void(0);

			var sorter:ArraySort = new ArraySort;

			var d:Object = thisAtom;
			var compare:Function = null;
			var altCompare:Function = null;
			var cmp:*;	// really Function, but needs to be undefined
			var opt:int = 0;
			var isNumericCompare:Boolean = false;
			if (args.length >= 1)
			{
				// function ptr
				var arg0:* = args[0];
				if (arg0 is Function)
				{
					// @todo make sure the sort function is callable
					cmp = arg0;
					compare = sorter.ScriptCompare;
					if (args.length >= 2)
					{
						var arg1:* = args[1];
						if ((arg1 is Number) || (arg1 is int) || (arg1 is uint))
						{
							opt = int(arg1);
						}
						else
						{
							// @todo wrong exception, should be kCheckTypeFailedError
							throw makeError( RangeError, 1005 /*kArrayIndexNotIntegerError*/, arg1 );
						}
					}
				}
				else if ((arg0 is Number) || (arg0 is int) || (arg0 is uint))
				{
					opt = int(arg0);
				}
				else
				{
					// @todo wrong exception, should be kCheckTypeFailedError
					throw makeError( RangeError, 1005 /*kArrayIndexNotIntegerError*/, arg0 );
				}
			}

			if (cmp === void(0))
			{
				if (opt & Array.NUMERIC) 
				{
					compare = sorter.NumericCompare;
					isNumericCompare = true;
				} 
				else if (opt & Array.CASEINSENSITIVE) 
				{
					compare = sorter.CaseInsensitiveStringCompare;
				} 
				else 
				{
					compare = sorter.StringCompare;
				}
			}

			if (opt & Array.DESCENDING) 
			{
				altCompare = compare;
				compare = sorter.DescendingCompare;
			}

			return sorter.sort(d, opt, compare, altCompare, cmp, null, isNumericCompare);
		}
		AS3 function sort(...args)
		{
			return _sort(this, args);
		}
		
		CONFIG::Full
		{
		    prototype.sort = function(...args)
		    {
			    return _sort(this, args);
		    }
		}

        CONFIG::Full
		private static function _sortOn(thisAtom:*, namesAtom:*, optionsAtom:*):*
		{
			if (!Object._isScriptObject(thisAtom))
				return void(0);
			
			var d:Object = thisAtom;

			// Possible combinations:
			//	Array.sortOn(String)
			//	Array.sortOn(String, options)
			//	Array.sortOn(Array of String)
			//	Array.sortOn(Array of String, options)
			//  Array.sortOn(Array of String, Array of options)

			//	What about options which must be global, such as kReturnIndexedArray?
			//	Perhaps it is the union of all field's options?
			
			var fn:Array = null;	// of FieldName
			var options:int = 0;
		
			if (namesAtom is String)
			{
				options = optionsAtom;
				fn = [new FieldName(namesAtom, options)];
			}
			else if (namesAtom is Array)
			{
				var obja:Array = namesAtom;
                var alen:uint = obja.length
				fn = new Array(alen);
				for (var i:uint = 0; i < alen; i++)
				{
					fn[i] = new FieldName(obja[i], 0);
				}

				if (optionsAtom is Array)
				{
					var obja:Array = optionsAtom;
					var alen:uint = obja.length
					if (alen == fn.length)
					{
						// The first options are used for uniqueSort and returnIndexedArray option
						options = obja[0];
						for (var i:uint = 0; i < alen; i++)
						{
							FieldName(fn[i]).options = int(obja[i]);
						}
					}
				}
				else
				{
					options = optionsAtom;
					var fnlen:uint = fn.length
					for (var i:uint = 0; i < fnlen; i++)
					{
						fn[i].options = options;
					}
				}
			}

			var sorter:ArraySort = new ArraySort;
			return sorter.sort(d, options, sorter.FieldCompare, null, void(0), fn, false);
		}
		
		CONFIG::Full
		AS3 function sortOn(names, options=0, ...ignored)
		{
			// this is our own addition so we don't have to make names be optional
			return _sortOn(this, names, options);
		}
		
		CONFIG::Full
		{
		    prototype.sortOn = function(names, options=0, ...ignored)
		    {
			    return _sortOn(this, names, options)
		    }
        }
        
//		// Array extensions that are in Mozilla...
//		// http://developer.mozilla.org/en/docs/Core_JavaScript_1.5_Reference:Global_Objects:Array
//		//
//		// These all work on generic objects (array like objects) as well as arrays
//

		// though this is not ECMA3, it is in our ECMA3 sanity tests... !
		private static function _indexOf(o, searchElement, fromIndex:int):int
		{
			if (Object._isScriptObject(o))
			{
				var olen:uint = o.length;
				var start:int = _clampIndex(fromIndex, olen);
				for (var i:uint = start; i < olen; i++)
				{
					if (o[i] === searchElement)
						return i;
				}
			}
			return -1;
		}
		AS3 function indexOf(searchElement, fromIndex=0):int
		{
			return _indexOf(this, searchElement, int(fromIndex));
		}
		
		CONFIG::Full
		{
		    prototype.indexOf = function(searchElement, fromIndex=0):int
		    {
			    return _indexOf(this, searchElement, int(fromIndex));
		    }
		}

		// though this is not ECMA3, it is in our ASC sanity tests... !
		private static function _lastIndexOf(o, searchElement, fromIndex:int):int
		{
			if (Object._isScriptObject(o))
			{
				// use int, not uint
				var olen:uint = o.length;
				var start:int = _clampIndex(fromIndex, olen);
				if (start == olen)
					start--;
				for (var i:int = start; i >= 0; --i)
				{
					if (o[i] === searchElement)
						return i;
				}
			}
			return -1;
		}
		AS3 function lastIndexOf(searchElement, fromIndex=0x7fffffff):int
		{
			return _lastIndexOf(this, searchElement, int(fromIndex));
		}
		
		CONFIG::Full
		{
		    prototype.lastIndexOf = function(searchElement, fromIndex=0x7fffffff):int
		    {
			    return _lastIndexOf(this, searchElement, int(fromIndex));
		    }
        }
        
		// though this is not ECMA3, it is in our ASC sanity tests... !
		// Returns true if every element in this array satisfies the provided testing function.
		private static function _every(o:*, callback:Function, thisObject:*):Boolean
		{
			if (!Object._isScriptObject(o) || !callback)
				return true;

			if ((callback is MethodClosure) && thisObject !== null && thisObject !== void(0)) 
			{
				throw makeError(TypeError, 1510); // kArrayFilterNonNullObjectError;
			}

			var len:uint = o.length;
			for (var i:uint = 0; i < len; i++)
			{
				var result:* = callback.AS3::call(thisObject, o[i], i, o);
				if (!result)
					return false;
			}

			return true;
		}
		AS3 function every(callback:Function, thisObject=null):Boolean
		{
			return _every(this, callback, thisObject);
		}
		
		CONFIG::Full
		{
		    prototype.every = function(callback:Function, thisObject=null):Boolean
		    {
			    return _every(this, callback, thisObject);
		    }
		}

		// though this is not ECMA3, it is in our ASC sanity tests... !
		// Creates a new array with all elements that pass the test implemented by the provided function.
		CONFIG::Full
		private static function _filter(o, callback:Function, thisObject):Array
		{
			var r:Array = new Array();

			if (!Object._isScriptObject(o) || !callback)
				return r;

			if ((callback is MethodClosure) && thisObject !== null && thisObject !== void(0)) 
			{
				throw makeError(TypeError, 1510); // kArrayFilterNonNullObjectError;
			}

			var len:uint = o.length;
			for (var i:uint = 0, j:uint = 0; i < len; i++)
			{
				var oi:* = o[i];
				var result:* = callback.AS3::call(thisObject, oi, i, o);
				if (result)
				{
					r[j++] = oi;
				}
			}

			return r;
		}
		
		CONFIG::Full
		AS3 function filter(callback:Function, thisObject=null):Array
		{
			return _filter(this, callback, thisObject);
		}
		
		CONFIG::Full
		{
		    prototype.filter = function(callback:Function, thisObject=null):Array
		    {
			    return _filter(this, callback, thisObject);
		    }
        }
        
		// though this is not ECMA3, it is in our ASC sanity tests... !
		// Calls a function for each element in the array.
		CONFIG::Full
		private static function _forEach(o, callback:Function, thisObject):void
		{
			if (!Object._isScriptObject(o) || !callback)
				return;

			if ((callback is MethodClosure) && thisObject !== null && thisObject !== void(0)) 
			{
				throw makeError(TypeError, 1510); // kArrayFilterNonNullObjectError;
			}

			var len:uint = o.length;
			for (var i:uint = 0; i < len; i++)
			{
				callback.AS3::call(thisObject, o[i], i, o);
			}
		}
		
		CONFIG::Full
		AS3 function forEach(callback:Function, thisObject=null):void
		{
			_forEach(this, callback, thisObject);
		}
		
		CONFIG::Full
		{
		    prototype.forEach = function(callback:Function, thisObject=null):void
		    {
			    _forEach(this, callback, thisObject);
		    }
		}

		// though this is not ECMA3, it is in our ASC sanity tests... !
		// Creates a new array with the results of calling a provided function on every element in this array.
		CONFIG::Full
		private static function _map(o, callback:Function, thisObject):Array
		{
			if (!Object._isScriptObject(o) || !callback)
				return [];

			if ((callback is MethodClosure) && thisObject !== null && thisObject !== void(0)) 
			{
				throw makeError(TypeError, 1510); // kArrayFilterNonNullObjectError;
			}

			var len:uint = o.length;
			var r:Array = new Array(len);
			for (var i:uint = 0; i < len; i++)
			{
				r[i] = callback.AS3::call(thisObject, o[i], i, o);
			}

			return r;
		}
		
		CONFIG::Full
		AS3 function map(callback:Function, thisObject=null):Array
		{
			return _map(this, callback, thisObject);
		}
		
		CONFIG::Full
		{
		    prototype.map = function(callback:Function, thisObject=null):Array
		    {
			    return _map(this, callback, thisObject);
		    }
		}
		
		// though this is not ECMA3, it is in our ASC sanity tests... !
		// Returns true if at least one element in this array satisfies the provided testing function.
		CONFIG::Full
		private static function _some(o, callback:Function, thisObject):Boolean
		{
			if (!Object._isScriptObject(o) || !callback)
				return false;

			if ((callback is MethodClosure) && thisObject !== null && thisObject !== void(0)) 
			{
				throw makeError(TypeError, 1510); // kArrayFilterNonNullObjectError;
			}

			var len:uint = o.length;
			for (var i:uint = 0; i < len; i++)
			{
				var result:* = callback.AS3::call(thisObject, o[i], i, o);
				if (result)
					return true;
			}

			return false;
		}
		
		CONFIG::Full
		AS3 function some(callback:Function, thisObject=null):Boolean
		{
			return _some(this, callback, thisObject);
		}
		
		CONFIG::Full
		{
		    prototype.some = function(callback:Function, thisObject=null):Boolean
		    {
			    return _some(this, callback, thisObject);
		    }
        }
        
		// --------------------------------------------------
		// private utility methods
		// --------------------------------------------------
		private static function _clampIndex(intValue:Number, len:uint):uint
		{
			var clamped:uint;
			if (intValue < 0.0) 
			{
				if (intValue + len < 0.0) 
					clamped = 0;
				else 
					clamped = intValue + len;
			} 
			else if (intValue > len) 
				clamped = len;
			else if (intValue !== intValue) // is NaN->uint conversion well-defined? if so, this may be unnecessary
				clamped = 0;
			else
				clamped = intValue;

			return clamped;
		}

		_hideproto(prototype);

	}

	internal final class FieldName 
	{
		public var name:String;
		public var options:int;
		
		function FieldName(n:String, o:int)
		{
			name = n;
			options = o;
		}
	};

	internal final class StackFrame
	{
		public var lo:uint;
		public var hi:uint;
	}

    /**
     * ArraySort implements actionscript Array.sort().
	 * It's also the base class SortWithParameters, which handles all other permutations of Array
     */
	internal final class ArraySort
	{
		/*************************************************************
		 * Forward declarations required by public methods
		 *************************************************************/

		/** Array.sortOn() will pass an array of field names */

		private var m_objectToSort:Object;
		private var m_options:int;

		private var m_cmpFunc:Function;
		private var m_altCmpFunc:Function;
		private var m_cmpExternalFunc:*;

		private var m_index:Array;	// uint32_t
		private var m_atoms:Array;		// Atom

		private var m_fields:Array	// FieldName
		private var m_fieldatoms:Array	// Atom

		/*************************************************************
		 * Public Functions
		 *************************************************************/

		public function sort(
			_d:Object,
			_options:int, 
			_cmpFunc:Function,		// CompareFuncPtr 
			_altCmpFunc:Function,	// CompareFuncPtr 
			_cmpActionScript:*, 
			_fields:Array,			// of FieldName
			isNumericCompare:Boolean
		) : Object
		{
			m_objectToSort = _d;
			m_options = _options;
			m_cmpFunc = _cmpFunc;
			m_altCmpFunc = _altCmpFunc;
			m_cmpExternalFunc = _cmpActionScript;
			m_index = null;
			m_atoms = null;
			m_fields = _fields;
			m_fieldatoms = null;

			var len:uint = m_objectToSort.length;
			var iFirstUndefined:uint = len;
			var iFirstAbsent:uint = len;

			if (len >= 0x10000000)
			{
				// @todo wrong exception
				throw makeError( RangeError, 1005 /*kArrayIndexNotIntegerError*/, len );
			}

			m_index = new Array(len);
			m_atoms = new Array(len);
			
			var i:Number;	// not uint
			var j:uint;
			var newlen:uint = len;

			// One field value - pre-get our field values so we can just do a regular sort
			if (m_fields != null && m_fields.length == 1)
			{
				m_fieldatoms = new Array(len);

				// note, loop needs to go until i = -1, 0xffffffff is a valid index, so use Number
				for (i = (len - 1), j = len; i >= 0; i--)
				{
					m_index[i] = i;
					var a:* = m_objectToSort[i];
					m_fieldatoms[i] = a;

					if (Object._isScriptObject(a))
					{
						// An undefined prop just becomes undefined in our sort
						m_atoms[i] = a[m_fields[0].name];
					}
					else
					{
						j--;

						var temp:uint = m_index[i];
						m_index[i] = m_index[j];
						
						if (m_objectToSort[i] === void(0))
						{
							newlen--;
							m_index[j] = m_index[newlen];
							m_index[newlen] = temp;
						} 
						else 
						{
							m_index[j] = temp;
						}
					}
				}

				var opt:int = m_fields[0].options;

				if (opt & Array.NUMERIC) 
				{
					m_cmpFunc = NumericCompare;
				} 
				else if (opt & Array.CASEINSENSITIVE) 
				{
					m_cmpFunc = CaseInsensitiveStringCompare;
				} 
				else 
				{
					m_cmpFunc = StringCompare;
				}

				if (opt & Array.DESCENDING) 
				{
					m_altCmpFunc = m_cmpFunc;
					m_cmpFunc = DescendingCompare;
				}
			}
			else
			{
				//var isNumericCompare:Boolean = (m_cmpFunc == NumericCompare) || (m_altCmpFunc == NumericCompare);
				// note, loop needs to go until i = -1, 0xffffffff is a valid index, so use Number
				for (i = (len - 1), j = len; i >= 0; i--)
				{
					m_index[i] = i;
					var oo:* = m_objectToSort[i];
					m_atoms[i] = m_objectToSort[i];

					// We want to throw if this is an Array.NUMERIC sort and any items are not numbers,
					// and not strings that can be converted into numbers
					if (isNumericCompare)
					{
						var nn:* = m_atoms[i];
						if (!(nn is Number) && !(nn is int) && !(nn is uint))
						{
							var val:Number = Number(nn);
							if (val !== val)
							{
								// @todo wrong exception, should be kCheckTypeFailedError
								throw makeError( RangeError, 1005 /*kArrayIndexNotIntegerError*/, val );
							}
						}
					}

					// getAtomProperty() returns undefined when that's the value of the property.
					// It also returns undefined when the object does not have the property.
					// 
					// SortCompare() from ECMA 262 distinguishes these two cases. The end
					// result is undefined comes after everything else, and missing properties
					// come after that.
					//
					// To simplify our compare, partitition the array into { defined | undefined | missing }
					// Note that every missing element shrinks the length -- we'll set this new
					// length at the end of this routine when we are done.

					if (m_atoms[i] === void(0)) 
					{
						j--;

						var temp:uint = m_index[i];
						m_index[i] = m_index[j];
						
						if (!m_objectToSort.hasOwnProperty(i)) 
						{
							newlen--;
							m_index[j] = m_index[newlen];
							m_index[newlen] = temp;
						} 
						else 
						{
							m_index[j] = temp;
						}
					}
				}
			}

			iFirstAbsent = newlen;
			iFirstUndefined = j;

			// The portion of the array containing defined values is now [0, iFirstUndefined).
			// The portion of the array containing values undefined is now [iFirstUndefined, iFirstAbsent).
			// The portion of the array containing absent values is now [iFirstAbsent, len).

			// now sort the remaining defined() elements
			qsort(0, j-1);
			
			if (m_options & Array.UNIQUESORT)
			{
				// todo : UNIQUESORT could throw an exception.
				// todo : UNIQUESORT could abort the sort once equal members are found
				for (i = 0; i < (len - 1); i++)
				{
					if (m_cmpFunc(i, (i+1)) == 0)
					{
						return 0;
					}
				}
			}

			if (m_options & Array.RETURNINDEXEDARRAY)
			{
				// return the index array without modifying the original array
				return m_index;
			}
			else
			{
				// If we need to use our m_fieldatoms as results, temporarily swap them with
				// our m_atoms array so the below code works on the right data. Fieldatoms contain
				// our original objects while m_atoms contain our objects[field] values for faster
				// sorting.
				var tempa:Array = m_atoms;
				if (m_fieldatoms != null)
				{
					m_atoms = m_fieldatoms;	
				}

				for (i = 0; i < iFirstAbsent; i++) 
				{
					m_objectToSort[i] = m_atoms[m_index[i]];
				}

				for (i = iFirstAbsent; i < len; i++) 
				{
					delete m_objectToSort[i];
				}

				//a->setLength(len);  ES3: don't shrink array on sort.  Seems silly
				m_atoms = tempa;
				return m_objectToSort;
			}
		}

		private function swap(j:uint, k:uint):void
		{
			var temp:uint = m_index[j];
			m_index[j] = m_index[k];
			m_index[k] = temp;
		}
	
		// non-recursive quicksort implementation
		private function qsort(lo:uint, hi:uint):void
		{
			// leave without doing anything if the array is empty (lo > hi) or only one element (lo == hi)
			if (lo >= hi)
				return;

			// This is an iterative implementation of the recursive quick sort.
			// Recursive implementations are basically storing nested (lo,hi) pairs
			// in the stack frame, so we can avoid the recursion by storing them
			// in an array.
			//
			// Once partitioned, we sub-partition the smaller half first. This means
			// the greatest stack depth happens with equal partitions, all the way down,
			// which would be 1 + log2(size), which could never exceed 33.

			var size:uint;
			var stk:Array = new Array(33);	// of StackFrame
			for (var i:int = 0; i < 33; i++)
				stk[i] = new StackFrame;
			var stkptr:int = 0;

			// code below branches to this label instead of recursively calling qsort()
//recurse:
			for (;;)
			{
				size = (hi - lo) + 1; // number of elements in the partition

				if (size < 4) 
				{
				
					// It is standard to use another sort for smaller partitions,
					// for instance c library source uses insertion sort for 8 or less.
					//
					// However, as our swap() is essentially free, the relative cost of
					// m_cmpFunc() is high, and with profiling, I found quicksort()-ing
					// down to four had better performance.
					//
					// Although verbose, handling the remaining cases explicitly is faster,
					// so I do so here.

					if (size == 3) 
					{
						if (m_cmpFunc(lo, lo + 1) > 0) 
						{
							swap(lo, lo + 1);
							if (m_cmpFunc(lo + 1, lo + 2) > 0) 
							{
								swap(lo + 1, lo + 2);
								if (m_cmpFunc(lo, lo + 1) > 0) 
								{
									swap(lo, lo + 1);
								}
							}
						} 
						else 
						{
							if (m_cmpFunc(lo + 1, lo + 2) > 0) 
							{
								swap(lo + 1, lo + 2);
								if (m_cmpFunc(lo, lo + 1) > 0) 
								{
									swap(lo, lo + 1);
								}
							}
						}
					} 
					else if (size == 2) 
					{
						if (m_cmpFunc(lo, lo + 1) > 0)
						{
							swap(lo, lo + 1);
						}
					} 
					else 
					{
						// size is one, zero or negative, so there isn't any sorting to be done
					}
				} 
				else 
				{
					// qsort()-ing a near or already sorted list goes much better if
					// you use the midpoint as the pivot, but the algorithm is simpler
					// if the pivot is at the start of the list, so move the middle
					// element to the front!
					var pivot:uint = lo + (size / 2);
					swap(pivot, lo);

					var left:uint = lo;
					var right:uint = hi + 1;

	// partition:
					for (;;) 
					{
						// Move the left right until it's at an element greater than the pivot.
						// Move the right left until it's at an element less than the pivot.
						// If left and right cross, we can terminate, otherwise swap and continue.
						//
						// As each pass of the outer loop increments left at least once,
						// and decrements right at least once, this loop has to terminate.

						do  
						{
							++left;
						} 
						while ((left <= hi) && (m_cmpFunc(left, lo) <= 0));

						do  
						{
							--right;
						} 
						while ((right > lo) && (m_cmpFunc(right, lo) >= 0));

						if (right < left)
							break;	// from partition: loop, not recurse: loop!

						swap(left, right);
					}

					// move the pivot after the lower partition
					swap(lo, right);

					// The array is now in three partions:
					//	1. left partition	: i in [lo, right), elements less than or equal to pivot
					//	2. center partition	: i in [right, left], elements equal to pivot
					//	3. right partition	: i in (left, hi], elements greater than pivot
					// NOTE : [ means the range includes the lower bounds, ( means it excludes it, with the same for ] and ).

					// Many quick sorts recurse into the left partition, and then the right.
					// The worst case of this can lead to a stack depth of size -- for instance,
					// the left is empty, the center is just the pivot, and the right is everything else.
					//
					// If you recurse into the smaller partition first, then the worst case is an
					// equal partitioning, which leads to a depth of log2(size).
					if ((right - 1 - lo) >= (hi - left)) 
					{
						if ((lo + 1) < right) 
						{
							var sf:StackFrame = stk[stkptr++];
							sf.lo = lo;
							sf.hi = right - 1;
						}

						if (left < hi)
						{
							lo = left;
							//goto recurse;
							continue;	// to recurse: loop
						}
					}
					else
					{
						if (left < hi)
						{
							var sf:StackFrame = stk[stkptr++];
							sf.lo = left;
							sf.hi = hi;
						}

						if ((lo + 1) < right)
						{
							hi = right - 1;
							//goto recurse;           /* do small recursion */
							continue;	// to recurse: loop
						}
					}
				}

				// we reached the bottom of the well, pop the nested stack frame
				if (--stkptr >= 0)
				{
					var sf:StackFrame = stk[stkptr];
					lo = sf.lo;
					hi = sf.hi;
					//goto recurse;
					continue;	// to recurse: loop
				}

				// we've returned to the top, so we are done!
				return;

			}	// end of recurse: endless loop
		}

		/*
		 * compare(j, k) as string's
		 */
		public function StringCompare(j:uint, k:uint):int
		{
			var x:Object = m_atoms[m_index[j]];
			var y:Object = m_atoms[m_index[k]];
			x = String(x)
			y = String(y)

			return x < y ? -1 : (x > y)
		}

		/*
		 * compare(j, k) as case insensitive string's
		 */
		public function CaseInsensitiveStringCompare(j:uint, k:uint):int 
		{
			var x:Object = m_atoms[m_index[j]];
			var y:Object = m_atoms[m_index[k]];

			x = x ? x.toString().AS3::toLowerCase() : "null";
			y = y ? y.toString().AS3::toLowerCase() : "null";

			if (x < y) return -1; 
			else if (x > y) return 1; 
			else return 0; 
		}

		/*
		 * compare(j, k) using an actionscript function
		 */
		public function ScriptCompare(j:uint, k:uint):int
		{
			// todo must figure out the kosher way to invoke
			// callbacks like the sort comparator.

			// todo what is thisAtom supposed to be for the
			// comparator?  Passing in the array for now.

			var x:Object = m_atoms[m_index[j]];
			var y:Object = m_atoms[m_index[k]];
			var result:Number = m_cmpExternalFunc(x, y);
			// cn: don't use core->integer on result of call.  The returned 
			//  value could be bigger than 2^32 and toInt32 will return the 
			//  ((value % 2^32) - 2^31), which could change the intended sign of the number.
			//  
			//return core->integer(o->call(a->atom(), args, 2));
			return (result > 0 ? 1 : (result < 0 ? -1 : 0));
		}

		public function DescendingCompare(j:uint, k:uint):int
		{
			return m_altCmpFunc(k, j);
		}

		/*
		 * compare(j, k) as numbers
		 */
		public function NumericCompare(j:uint, k:uint):int
		{
			var atmj:Object = m_atoms[m_index[j]];
			var atmk:Object = m_atoms[m_index[k]];
			// Integer checks makes an int array sort about 3x faster.
			// A double array sort is 5% slower because of this overhead
			if ((atmj is int) && (atmk is int))
			{
				return (int(atmj) - int(atmk));
			}
			
			var x:Number = Number(atmj);
			var y:Number = Number(atmk);
			var diff:Number = x - y;

			if (diff === diff) 
			{ 
				// same as !isNaN
				return (diff < 0.0) ? -1 : ((diff > 0.0) ? 1 : 0);
			} 
			else if (y === y) 
			{
				return 1;
			} 
			else if (x === x) 
			{
				return -1;
			} 
			else 
			{
				return 0;
			}
		}

		/*
		 * FieldCompare is for Array.sortOn()
		 */
		public function FieldCompare(lhs:uint, rhs:uint):int
		{
			var opt:int = m_options;
			var result:int = 0;

			var obj_j:Object = m_atoms[m_index[lhs]];
			var obj_k:Object = m_atoms[m_index[rhs]];

			if (!(obj_j && obj_k))
			{
				if (obj_k) 
				{
					result = 1;
				} 
				else if (obj_j) 
				{
					result = -1;
				} 
				else 
				{
					result = 0;
				}
				return (opt & Array.DESCENDING) ? -result : result;
			}

			for (var i:uint = 0; i < m_fields.length; i++)
			{
				var name:String = m_fields[i].name;
				opt = m_fields[i].options; // override the group defaults with the current field

				var x:* = obj_j[name];
				var y:* = obj_k[name];

				var def_x:Boolean = (x !== void(0));
				var def_y:Boolean = (y !== void(0));

				if (!(def_x && def_y))
				{
					// ECMA 262 : Section 15.4.4.11 lists the rules.
					// There is a difference between the object has a property
					// with value undefined, and it does not have the property,
					// for which getAtomProperty() returns undefined.

					// def_x implies has_x
					// def_y implies has_y

					if (def_y) 
					{							
						result = 1;
					} 
					else if (def_x) 
					{
						result = -1;
					} 
					else 
					{
						var has_x:Boolean = obj_j.hasOwnProperty(name);
						var has_y:Boolean = obj_k.hasOwnProperty(name);

						if (!has_x && has_y) 
						{
							result = 1;
						} 
						else if (has_x && !has_y) 
						{
							result = -1;
						} 
						else 
						{
							result = 0;
						}
					}
				} 
				else if (opt & Array.NUMERIC) 
				{
					var lhsn:Number = Number(x);
					var rhsn:Number = Number(y);
					var diffn:Number = lhsn - rhsn;

					if (diffn === diffn) 
					{ 
						// same as !isNaN
						result = (diffn < 0.0) ? -1 : ((diffn > 0.0) ? 1 : 0);
					} 
					else if (rhsn === rhsn) 
					{
						result = 1;
					} 
					else if (lhsn === lhsn) 
					{
						result = -1;
					} 
					else 
					{
						result = 0;
					}
				}
				else
				{
					var str_lhs:String = x ? x.toString() : "null";
					var str_rhs:String = y ? y.toString() : "null";

					if (opt & Array.CASEINSENSITIVE)
					{
						str_lhs = str_lhs.AS3::toLowerCase();
						str_rhs = str_rhs.AS3::toLowerCase();
					}

					if (str_lhs < str_rhs) result = -1; 
					else if (str_lhs > str_rhs) result = 1; 
					else result = 0; 
				}

				if (result != 0)
					break;
			}

			if (opt & Array.DESCENDING)
				return -result;
			else
				return result;
		}
	}
}
