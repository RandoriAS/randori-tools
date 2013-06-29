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
	[JavaScript(export="false", name="Error")]
	[native(cls="ErrorClass", instance="ErrorObject", methods="auto")]
	public dynamic class Error
	{
		prototype.name = "Error"
		prototype.message = "Error"

		// Error.length = 1 per ES3
		// E262 {ReadOnly, DontDelete, DontEnum }
		public static const length:int = 1

		// TODO mark message as String once compiler super() bug is fixed	
		// E262 {}
		/* enumerable */ public var message;
        public var name;
		
		// JS Error has these props:  
		//	  message:String
		//    fileName:String
		//    lineNumber:String
		//    stack:String
		//    name:String
		
		function Error(message = "")
		{
			this.message = message;
	            this.name = prototype.name;
		}

		prototype.toString = function():String
		{
            var e:Error = this
            return e.message !== "" ? e.name + ": " + e.message : e.name;
		}
		_setPropertyIsEnumerable(prototype, "toString", false);

		// avm+ specific, works in debugger builds only
		public native function getStackTrace():String;
		public native static function getErrorMessage(index:int):String;

	}

	[native(cls="EvalErrorClass", instance="EvalErrorObject", methods="auto")]
	public dynamic class EvalError extends Error 
	{
		// E262 {ReadOnly, DontDelete, DontEnum }
		public static const length:int = 1

		prototype.name = "EvalError"
		function EvalError(message = "") 
		{
			super(message);
            this.name = prototype.name;
		}
	}

	[native(cls="RangeErrorClass", instance="RangeErrorObject", methods="auto")]
	public dynamic class RangeError extends Error 
	{
		// E262 {ReadOnly, DontDelete, DontEnum }
		public static const length:int = 1

		prototype.name = "RangeError"
		function RangeError(message = "") 
		{
			super(message, id);
            this.name = prototype.name;
		}	
	}

	[native(cls="ReferenceErrorClass", instance="ReferenceErrorObject", methods="auto")]
	public dynamic class ReferenceError extends Error 
	{
		// E262 {ReadOnly, DontDelete, DontEnum }
		public static const length:int = 1

		prototype.name = "ReferenceError"
		function ReferenceError(message = "") 
		{
			super(message);
            this.name = prototype.name;
		}
	}

	[native(cls="SyntaxErrorClass", instance="SyntaxErrorObject", methods="auto")]
	public dynamic class SyntaxError extends Error 
	{
		// E262 {ReadOnly, DontDelete, DontEnum }
		public static const length:int = 1

		prototype.name = "SyntaxError"
		function SyntaxError(message = "") 
		{
			super(message);
            this.name = prototype.name;
		}	
	}

	[native(cls="TypeErrorClass", instance="TypeErrorObject", methods="auto")]
	public dynamic class TypeError extends Error
	{
		// E262 {ReadOnly, DontDelete, DontEnum }
		public static const length:int = 1

		prototype.name = "TypeError"
		function TypeError(message = "") 
		{
			super(message);
            this.name = prototype.name;
		}	
	}

	[native(cls="URIErrorClass", instance="URIErrorObject", methods="auto")]
	public dynamic class URIError extends Error 
	{
		// E262 {ReadOnly, DontDelete, DontEnum }
		public static const length:int = 1

		prototype.name = "URIError"
		function URIError(message = "") 
		{
			super(message);
            this.name = prototype.name;
		}	
	}

}
