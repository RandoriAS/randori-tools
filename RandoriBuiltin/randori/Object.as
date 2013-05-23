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
 * Portions created by the Initial Developer are Copyright (C) 2004-2006
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
	
	/* 
	AS3 implementation constraint:
	Object cannot have any per-instance properties, because it is extended by Boolean, String,
	Number, Namespace, int, and uint, which cannot hold inherited state from Object because
	we represent these types more compactly than with ScriptObject.
	
	It's desirable to avoid using "protected" here, to avoid having to propagate a protected namespace
	into every class in existence.
	*/
	 
	public dynamic class Object
	{
		// Object.length = 1 per ES3
		// E262 {ReadOnly, DontDelete, DontEnum }
		public static const length:int = 1

		nativeHookNS function inHook(n:*):Boolean 
		{ 
			var s:String = _intern(n);

			if (_hasPB(this, s))
				return true;

			var o:Object = this._toObj();
			while (o)
			{
				if (o.AS3::hasOwnProperty(s))	// @todo need to use hasProperyHook, rewrite in Forth
					return true;

				o = (o is Object) ? o._getDelegate() : null;
			}

			return false;
		}
		
		[forth(word="w_hasDynamicProperty")]
		final private native function _hasDynamicProperty(n:*):Boolean;

		[forth(word="w_setdelegate")]
		final private native function _setDelegate(o:Object):void;

		internal function set __proto__(o:Object):void { _setDelegate((o is Object) ? o : null); }
				
		[forth(word="w_getdelegate")]
		final private native function _getDelegate():Object;

		[forth(word="w_getPropertyEnumerable")]
		final private native function _getPropEnum(V:String):Boolean;

		[forth(word="w_setPropertyEnumerable")]
		private static native function _setPropertyEnumerable(o:*, propname:String, enumerable:Boolean):void;
				
		[forth(word="w_isPrototypeOf")]
		private static native function _isPO(o:*, V:*):Boolean

		[forth(word="w_toString")]
		// note: the implementation may return a String or an int-atom, so wrap the result in String()
		private static native function _toStr(o:*):*

		[forth(word="w_intern")]
		private static native function _intern(o:*):String;

		[forth(word="w_hasPublicBinding")]
		private static native function _hasPB(self:*, s:String):Boolean;
		
		[forth(word="w_toclass")]
		private static native function _toclass(o:*):Class;

		// AS3 equivalent to AvmCore::isScriptObject, which is really "isScriptObject",
		// which is NOT the same as AS3 "is Object"...

		[forth(word="w_isScriptObject")]
		internal static native function _isScriptObject(o:*):Boolean;
		
		// implements "_isScriptObject(o) ? o : _toclass(o).prototype"
		[forth(word="w_toRealObject")]
		private final native function _toObj():Object;

		nativeHookNS function tostringHook():*
		{
			var s = this.public::toString()
			if (!_isScriptObject(s))
				return s
			return this.public::valueOf()
		}
		
		nativeHookNS function defaultvalueHook():*
		{
			var v = this.public::valueOf()
			if (!_isScriptObject(v))
				return v
			return this.public::toString()
		}

		AS3 function isPrototypeOf(V=void 0):Boolean
		{
			return _isPO(this,V)
		}
		
		AS3 function hasOwnProperty(V=void 0):Boolean
		{
			var name:String = _intern(String(V));

			if (_hasPB(this, name))
				return true;

			return _isScriptObject(this) && _hasDynamicProperty(name);
		}

		AS3 function propertyIsEnumerable(V=void(0)):Boolean
		{
			return this._getPropEnum(String(V));
		}

		internal static function _hideproto(proto:Object):void
		{
			for (var name:String in proto)
			{
				_setPropertyEnumerable(proto, String(name), false);
			}
		}
		
		// delay proto functions until class Function is initialized.
		internal static function init()
		{
			prototype.hasOwnProperty =
			function(V=void 0):Boolean
			{
				return this.AS3::hasOwnProperty(V);
			}

			prototype.propertyIsEnumerable = function(V=void 0)
			{
				return this.AS3::propertyIsEnumerable(V);
			}

			prototype.setPropertyIsEnumerable = function(name:String,enumerable:Boolean):void
			{
				_setPropertyEnumerable(this, String(name), enumerable);
			}

			prototype.isPrototypeOf = function(V=void 0):Boolean
			{
				return this.AS3::isPrototypeOf(V);
			}

            CONFIG::Full
            {
			    prototype.toString = prototype.toLocaleString = 
			    function():String
			    {
			        return ((this is Class) ? "[class " : "[object ") + String(_toStr(this)) + "]"
			    }

			    prototype.valueOf = function()
			    {
				    return this;
			    }
			}

			_hideproto(prototype);
		}
	}

}
