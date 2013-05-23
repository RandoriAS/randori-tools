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
	//pseudo-final - no user class can extend Function
	dynamic public class Function
	{
		[native(type="MethodEnv*")]
		private var methodEnv:*;

		private static function ctorError(args:Array):Function
		{
			if (args.length != 0)
			{
				throw makeError( EvalError, 1066 /*kFunctionConstructorError*/, "Function" );
			}
			return function() {}
		}

		nativeHookNS static function callHook(...args):* 
		{ 
			return ctorError(args); 
		}
		nativeHookNS static function constructHook(...args):* 
		{ 
			return ctorError(args); 
		}

		// E262 {DontDelete}
		// JS {DontEnum,DontDelete}
		[forth(word="w_prototype_get")]
		public native function get prototype():*;
		
		[forth(word="w_prototype_set")]
		final private native function set _prototype(p:*):void
		public function set prototype(p:*):void
		{
		    if (p == null || _isScriptObject(p))
		        private::_prototype = p
		    else
		        throw makeError(TypeError,1049 /* kPrototypeTypeError */)
		}
		
		// E262 {DontEnum, DontDelete, ReadOnly}
		[forth(word="w_Function_length")]
		public native function get length():int;

        internal::prototype = function () {}
        prototype.__proto__ = Object.prototype
        prototype.constructor = Function

        CONFIG::Full
        {
		    // NOTE: optional args aren't allowed at all for C++ native methods.
		    // They are allowed for forth native methods but the values are ignored
		    // (ie, they are useful for getting the method signature correct)
		    // the Forth implementation is responsible for checking argc and filling in the default value in this case!
		    [forth(word="w_Function_call")]
		    AS3 native function call(thisArg:* = void(0), ...args):*;

		    // Note, _apply assumes that argArray is Array (or null/void) and will crater
		    // on other objects. if you can't guarantee the type then you should call
		    // apply, not _apply.
		    [forth(word="w_Function_apply")]
		    final private native function _apply(thisArg:*, argArray:Array):*;

		    // native methods cannot have default arg values anymore, so wrap it
		    AS3 function apply(thisArg:* = void(0), argArray:* = void(0)):* 
		    { 
			    if (argArray && !(argArray is Array))
				    throw makeError(TypeError, 1116 /*kApplyError*/);

			    return this.private::_apply(thisArg, argArray); 
		    }

		    prototype.apply = function(thisArg:* = void(0), argArray:* = void(0)):*
		    {
			    // call apply, not _apply, so that arg checking is done
			    return this.AS3::apply(thisArg, argArray);
		    }
		
		    // @todo srj... we'd like this to be native-forth as well but there
		    // isn't currently a way of making a prototype function native without
		    // wrapping it, and there also isn't currently a way to wrap a restargs
		    // function without the array building occurring (which is what we're trying to avoid)
		    // so this version of call just uses apply...
		    prototype.call = function(thisArg:* = void(0), ...args):*
		    {
			    return this.private::_apply(thisArg, args);
		    }
		}
		
		// Function.length = 1 per ES3
		// E262 {ReadOnly, DontDelete, DontEnum }
		public static const length:int = 1

		/* cn:  Spidermonkey returns the actual source text of the function here.  The ES3
		//  standard only says:
			15.3.4.2 Function.prototype.toString ( )
			An implementation-dependent representation of the function is returned. This 
			representation has the syntax of a FunctionDeclaration. Note in particular 
			that the use and placement of white space, line terminators, and semicolons 
			within the representation string is implementation-dependent.
			The toString function is not generic; it throws a TypeError exception if its this value is not a Function object.
			Therefore, it cannot be transferred to other kinds of objects for use as a method.		
		//
		// We don't have the source text, so this impl follows the letter if not the intent
		//  of the spec.  
		//
		// Note: we only honor the compact ES3/4 spec, which means 
		//  we don't support new Function(stringArg) where stringArg is the text of
		//  the function to be compiled at runtime.  Returning the true text of the
		//  function in toString() seems to be a bookend to this feature to me, and
		//  thus shouldn't be in the compact specification either. */

		prototype.toLocaleString =
		prototype.toString = function():String
		{
			var f:Function = this
			return "function Function() {}"
		}

		_hideproto(prototype);

		// dont create Object's proto functions until after class Function is initialized
		Object.init();
	}

}
