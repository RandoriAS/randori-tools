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
	// arguments for DateToString()
	CONFIG const kToString = 0;
	CONFIG const kToDateString = 1;
	CONFIG const kToTimeString = 2;
	CONFIG const kToLocaleString = 3;
	CONFIG const kToLocaleDateString = 4;
	CONFIG const kToLocaleTimeString = 5;
	CONFIG const kToUTCString = 6;

	// arguments for setDateProperty()
	CONFIG const k_setFullYear = 1;
	CONFIG const k_setMonth = 2;
	CONFIG const k_setDate = 3;
	CONFIG const k_setHours = 4;
	CONFIG const k_setMinutes = 5;
	CONFIG const k_setSeconds = 6;
	CONFIG const k_setMilliseconds = 7;

	// misc useful constants
	CONFIG const kMsecPerDay = 86400000;
	CONFIG const kMsecPerHour = 3600000;
	CONFIG const kMsecPerSecond = 1000;
	CONFIG const kMsecPerMinute = 60000;
	CONFIG const kSecondsPerMinute = 60;
	CONFIG const kMinutesPerHour = 60;
	CONFIG const kHoursPerDay = 24;
	
	CONFIG const asciiSpace = 32;
	CONFIG const asciiPlus = 43;
	CONFIG const asciiComma = 44;
	CONFIG const asciiMinus = 45;
	CONFIG const asciiSlash = 47;
	CONFIG const asciiZero = 48;
	CONFIG const asciiNine = 57;
	CONFIG const asciiColon = 58;
	CONFIG const ascii_A = 65;
	CONFIG const ascii_Z = 90;
	CONFIG const ascii_a = 97;
	CONFIG const ascii_z = 122;
   	CONFIG const kHalfTimeDomain = 8.64e15;

	public final dynamic class Date
	{
		// @todo -- this is an extremely literal conversion of the C++ Date/DateObject/DateClass code from Tamarin.
		// it can probably be smartened in various ways.
		
		private static native function _getDate():Number;
		private static native function _localTZA(time:Number):Number;
		private static native function _daylightSavingTA(time:Number):Number;
		private static native function _doubleToIntDouble(n:Number):Number;

		// ------------------------------
		private static function TimeClip(t:Number):Number
		{
			if (!isFinite(t) || ((t < 0 ? -t : t) > CONFIG::kHalfTimeDomain))
			{
				return NaN;
			}
			return _doubleToIntDouble(t);
		}

		private static function DateFromYMDHMSM(year:Number, month:Number, date:Number, hours:Number, minutes:Number, seconds:Number, ms:Number, utcFlag:Boolean):Number
		{
			if (year < 100) 
			{
				year += 1900;
			}
			var t:Number = MakeDate(MakeDay(year, month, date), MakeTime(hours, minutes, seconds, ms));
			if (!utcFlag) 
			{
				t = TimeToUTC(t);
			}
			return t;
		}

		private static function Day(t:Number):Number
		{
			return Math.floor(t / CONFIG::kMsecPerDay);
		}

		private static function DayFromYear(year:Number):Number
		{
			return (365 * (year - 1970) +
					Math.floor((year - 1969) / 4) -
					Math.floor((year - 1901)/100) +
					Math.floor((year - 1601) / 400));
		}

		private static function TimeFromYear(year:int):Number
		{
			return CONFIG::kMsecPerDay * DayFromYear(year);
		}

		private static function DaysInYear(year:int):int
		{
			if (year % 4) 
			{
				return 365;
			}
			if (year % 100) 
			{
				return 366;
			}
			if (year % 400) 
			{
				return 365;
			}
			return 366;
		}

		private static function TimeWithinDay(t:Number):Number
		{
			var result:Number = t % CONFIG::kMsecPerDay;
			if (result < 0)
				result += CONFIG::kMsecPerDay;
			return result;
		}

		// NOTE: this is used by the Player core code. Changing this will change legacy behavior.
		private static function YearFromTime(t:Number):Number
		{
		    if (t !== t)
		        return t
		        
			var day:Number = Day(t);
			var lo:int = Math.floor((t < 0) ? (day / 365) : (day / 366)) + 1970;
			var hi:int = Math.ceil((t < 0) ? (day / 366) : (day / 365)) + 1970;
			while (lo < hi) 
			{
				// 13may04 grandma :
				// This was pivot = (lo + hi) / 2, but bug 89715 inadvertantly calls this with
				// t = -6.5438017398347670e+019, which produces lo = -2075023950 and hi = -2069354479,
				// and (lo + hi) overflows. The below expression won't overflow
				//int pivot = (lo / 2) + (hi / 2) + (lo & hi & 1);

				// 8/17/04 edsmith: 
				// the above expression does overflow, with other large numbers.
				// this one below uses double math to avoid overflow.
				var pivot:int = int(Math.floor((Number(lo) + Number(hi)) * 0.5));
				var pivotTime:Number = TimeFromYear(pivot);
				if (pivotTime <= t) 
				{
					if (TimeFromYear(pivot + 1) > t) 
					{ 
						// R41
						return pivot;
					} 
					else 
					{
						lo = pivot + 1;
					}
				} 
				else if (pivotTime > t) 
				{
					hi = pivot - 1;
				}
			}
			return lo;
		}

		private static function IsLeapYear(year:int):Boolean
		{
			return DaysInYear(year) == 366;
		}

		private static function TimeInLeapYear(t:Number):Boolean
		{
			return IsLeapYear(YearFromTime(t));
		}

		private static function DayWithinYear(t:Number):int
		{
			return int(Day(t) - DayFromYear(int(YearFromTime(t))));
		}

		private static const kMonthOffset:Array = [
			// Jan Feb Mar Apr May  Jun  Jul  Aug  Sep  Oct  Nov  Dec  Total
			[ 0,  31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334, 365 ],
			[ 0,  31, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335, 366 ]
		];

		private static function MonthFromTime(t:Number):Number
		{
		    if (t !== t)
		        return t
		        
			var day:int = DayWithinYear(t);
			var leap:int = int(TimeInLeapYear(t));

			var i:int;
			for (i=0; i < 11; ++i) 
			{
				if (day < kMonthOffset[leap][i+1]) 
				{
					break;
				}
			}
			return i;
		}

		private static function DateFromTime(t:Number):Number
		{
		    if (t !== t)
		        return t
		        
			var month:int = MonthFromTime(t);
			return DayWithinYear(t) - kMonthOffset[uint(TimeInLeapYear(t))][month] + 1;
		}

		private static function WeekDay(t:Number):Number
		{
		    if (t !== t)
		        return t
		        
			var result:int = (Day(t) + 4) % 7;
			if (result < 0) 
			{
				result = 7 + result;
			}
			return result;
		}

		private static function TimeToUTC(t:Number):Number
		{
			return (t - _localTZA(t) - _daylightSavingTA(t - _localTZA(t)));
		}

		private static function LocalTime(t:Number):Number
		{
			return (t + _localTZA(t) + _daylightSavingTA(t));
		}

        CONFIG::Full
		private static function GetTimezoneOffset(t:Number):Number
		{
			return (t - LocalTime(t)) / CONFIG::kMsecPerMinute;
		}

		private static function HourFromTime(t:Number):Number
		{
		    if (t !== t)
		        return t
		        
			var result:int = Math.floor((t + 0.5) / CONFIG::kMsecPerHour) % CONFIG::kHoursPerDay;
			if (result < 0) 
			{
				result += CONFIG::kHoursPerDay;
			}
			return result;
		}

		private static function DayFromMonth(year:Number, month:Number):Number
		{
			var iMonth:int = int(Math.floor(month));
			if (iMonth < 0 || iMonth >= 12) 
			{
				return NaN;
			}
			return DayFromYear(int(year)) + kMonthOffset[uint(IsLeapYear(year))][iMonth];
		}

		private static function MinFromTime(time:Number):Number
		{
		    if (time !== time)
		        return time
		        
			var result:int = Math.floor(time / CONFIG::kMsecPerMinute) % CONFIG::kMinutesPerHour;
			if (result < 0) 
			{
				result += CONFIG::kMinutesPerHour;
			}
			return result;
		}

		private static function SecFromTime(time:Number):Number
		{
		    if (time !== time) 
		        return time
		        
			var result:int = Math.floor(time / CONFIG::kMsecPerSecond) % CONFIG::kSecondsPerMinute;
			if (result < 0) 
			{
				result += CONFIG::kSecondsPerMinute;
			}
			return result;
		}

		private static function MsecFromTime(time:Number):Number
		{
		    if (time !== time)
		        return time
		        
			var result:int = time % CONFIG::kMsecPerSecond;
			if (result < 0) 
			{
				result += CONFIG::kMsecPerSecond;
			}
			return result;
		}

		private static function MakeDate(day:Number, time:Number):Number
		{
			// if any value is not finite, return NaN
			if (!isFinite(day) || !isFinite(time))
				return NaN;

			day = _doubleToIntDouble(day);
			time = _doubleToIntDouble(time);
			
			return day * CONFIG::kMsecPerDay + time;
		}

		private static function MakeTime(hour:Number, min:Number, sec:Number, ms:Number):Number
		{
			// if any value is not finite, return NaN
			if (!isFinite(hour) || !isFinite(min) || !isFinite(sec) || !isFinite(ms))
				return NaN;

			hour = _doubleToIntDouble(hour);
			min  = _doubleToIntDouble(min);
			sec  = _doubleToIntDouble(sec);
			ms   = _doubleToIntDouble(ms);
			
			return hour * CONFIG::kMsecPerHour + min * CONFIG::kMsecPerMinute + sec * CONFIG::kMsecPerSecond + ms;
		}

		private static function MakeDay(year:Number, month:Number, date:Number):Number
		{
			// if any value is not finite, return NaN
			if (!isFinite(year) || !isFinite(month) || !isFinite(date))
				return NaN;

			year  = _doubleToIntDouble(year);
			month = _doubleToIntDouble(month);
			date  = _doubleToIntDouble(date);

			year += Math.floor(month / 12);
			month %= 12;
			if (month < 0) 
			{
				month += 12;
			}
			return DayFromMonth(year, month) + (date - 1);
		}


		// To not change a particular value, pass NaN.
		private static function set_HMSM(time:Number, hours:Number, min:Number, sec:Number, msec:Number, utcFlag:Boolean):Number
		{
			var t:Number = utcFlag ? time : LocalTime(time);

			if (hours !== hours)
			{
				hours = HourFromTime(t);
			}
			if (min !== min)
			{
				min = MinFromTime(t);
			}
			if (sec !== sec)
			{
				sec = SecFromTime(t);
			}
			if (msec !== msec)
			{
				msec = MsecFromTime(t);
			}
			t = MakeDate(Day(t), MakeTime(hours, min, sec, msec));

			return TimeClip(utcFlag ? t : TimeToUTC(t));
		}

		private static function set_YMD(time:Number, year:Number, month:Number, date:Number, utcFlag:Boolean):Number
		{
			var t:Number = utcFlag ? time : LocalTime(time);

			// date may already be NaN.  It stays as NaN unless we are setting the year
			if (time !== time)
			{
				if (year !== year)
					return time;

				t = 0; // treat time as zero.
			}

			if (year !== year)
			{
				year = YearFromTime(t);
			}
			if (month !== month)
			{
				month = MonthFromTime(t);
			}
			if (date !== date)
			{
				date = DateFromTime(t);
			}

			// cn 2/14/06  Not sure whent this was added, but its not ECMAScript compatible.
			//   Yes, we will unexpectedly roll over into the next month and that's what
			//   the spec says to do.  Disabling this "correction"
			/*
			// If we are setting the month on the 31st to a month that has 30 days,
			// this will have the unexpected effect of rolling the date over into
			// the next month.  Correct for that here.
			int iMonth = (int)month;
			int iDate  = (int)date;
			int leap   = IsLeapYear((int)year);
			if (iMonth >= 0 && iMonth <= 11 && iDate >= 1 && iDate <= 31 ) {
				if (iDate >= DaysInMonth(leap, iMonth)) {
					iDate = DaysInMonth(leap, iMonth);
					date = (double)iDate;
				}
			}
			*/
			
			t = MakeDate(MakeDay(year, month, date), TimeWithinDay(t));
			return TimeClip(utcFlag ? t : TimeToUTC(t));
		}
	
		private function setDateProperty(index:int, args:Array):Number
		{
			var num:Array = [ NaN, NaN, NaN, NaN, NaN, NaN, NaN ];
			var utcFlag:Boolean = false;
			if (index < 0)
			{
				index = -index;
				utcFlag = true;
			}
			var j:int = index - 1;

			var argc:uint = uint(args.length);
			for (var i:uint = 0; i < argc; ++i) 
			{
				if (j >= 7) 
				{
					break;
				}
				var t:Number = args[i]
				num[j++] = t
				if (t !== t) 
				{	
					// actually specifying NaN results in a NaN date. Don't pass Nan, however, because we use 						    
					// that value to denote that an optional arg was not supplied.
					return m_time = t;
				}
			}

			const minTimeSetterIndex:int = 4; // any setNames index >= 4 should call setTime() instead of setDate()
											  //  setFullYear/setUTCFullYear/setMonth/setUTCMonth/setDay/setUTCDay are all in indices < 3
			if (index < minTimeSetterIndex)
			{
				m_time = set_YMD(m_time, num[0], num[1], num[2], utcFlag);
			}
			else
			{
				m_time = set_HMSM(m_time, num[3], num[4], num[5], num[6], utcFlag); 
			}
			return m_time;
		}
		
		CONFIG::Full
		{
    		private static const kMonths:Array = [ "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" ];
    		private static const kDaysOfWeek:Array = [ "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat" ];

		    private static function TwoDigit(i:int):String
		    {
			    var s:String = i.toString();
			    if (s.length == 1)
				    s = "0" + s;
			    return s;
		    }

		    private static function HMS(h:int, m:int, s:int):String
		    {
			    return TwoDigit(h)+":"+TwoDigit(m)+":"+TwoDigit(s);
		    }

		    private static function DateToString(t:Number, formatIndex:int):String
		    {
			    // todo we could try to do a much better job on
			    // localized date stuff
    			
			    if (t !== t)
			    {
				    return "Invalid Date";
			    }
    			
			    var time:Number = t;

			    if (formatIndex != CONFIG::kToUTCString) 
			    {
				    time = LocalTime(t);
			    }

			    var yearr:int = YearFromTime(time);
			    var month:int = MonthFromTime(time);
			    var day:int = WeekDay(time);
			    if (month < 0 || month >= 12 || day < 0 || day >= 7) 
			    {
				    return "";
			    }
    			
			    var delta:int = int((time - t) / CONFIG::kMsecPerMinute);
			    var signChar:String = "+";
			    if (delta < 0) 
			    {
				    delta = -delta;
				    signChar = "-";
			    }
			    var deltaH:int = (delta / 60);
			    var deltaM:int = (delta % 60);

			    var date:int = int(DateFromTime(time));

			    const hour24:int = int(HourFromTime(time));
			    var hour12:int = hour24 % 12;
			    if (hour12 == 0) 
			    {
				    hour12 = 12;
			    }
			    const ampm:String = (hour24 >= 12) ? "PM" : "AM";

			    const min:int = int(MinFromTime(time));
			    const seconds:int = int(SecFromTime(time));

			    const dayOfWeekStr:String = kDaysOfWeek[day];
			    const monthStr:String = kMonths[month];
    			
			    switch (formatIndex) 
			    {
				    /* CN:  ecma3 leaves the string format implementation dependent, as long
				    /   as it contains all the info below.  As a result, IE and Mozilla
				    /   had different formats for date.  In 2002, Mozilla changed their date
				    /   format to make it easier to write code which parses dates in string format 
				    /   regardless of the implementation which produced it.
				    /   http://bugzilla.mozilla.org/show_bug.cgi?id=118266 
				    /   We are not required by the standard to follow suit, but the one of the goals
				    /   of compliance is easy porting of code / techniques from ecmascript.  This change
				    /   should be done in a AS2/AS3 conditional manner, however:

				    // CN: 1/8/05 well, maybe this does break some existing user code (like the ATS).  Since
				    //  we aren't required to match Spidermonkey by the ES3 spec, lets decide to break
				    //  existing ECMAscript code over existing Actionscript code.

				    //AS2.0 format:

				    */
				    case CONFIG::kToString:
					    return dayOfWeekStr + " " + monthStr + " " + date.toString() + " " + HMS(hour24,min,seconds) + " GMT" + signChar + TwoDigit(deltaH) + TwoDigit(deltaM) + " " + yearr.toString();

				    case CONFIG::kToLocaleString:
					    return dayOfWeekStr + " " + monthStr + " " + date.toString() + " " + yearr.toString() + " " + HMS(hour12,min,seconds) + " " + ampm;

				    case CONFIG::kToUTCString:
					    return dayOfWeekStr + " " + monthStr + " " + date.toString() + " " + HMS(hour24,min,seconds) + " " + yearr.toString() + " UTC";
    						
				    case CONFIG::kToDateString:
				    case CONFIG::kToLocaleDateString:
					    return dayOfWeekStr + " " + monthStr + " " + (int(DateFromTime(time))).toString() + " " +(int(YearFromTime(time))).toString();

				    case CONFIG::kToTimeString:
					    return HMS(hour24,min,seconds) + " GMT" + signChar + TwoDigit(deltaH) + TwoDigit(deltaM);

				    case CONFIG::kToLocaleTimeString:
					    return HMS(hour12,min,seconds) + " " + ampm;
			    }
			    return "";
		    }

		    static const kDayAndMonthKeywords:Array = [ "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec", "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "GMT", "UTC" ];
    		static const kKeyWordLength:int = 3;
    		static const kUtcKewordPos:int = 12+7+1;

		    // Identify keyword within substring of <s> and modify hour, month,
		    //  or timeZoneOffset appropriately.  Return false if keyword is
		    //  invalid.   Assumes that <offset> is the start of a word in <s> and
		    //  <offset> + <count> marks the end of that word.
		    private static function parseDateKeyword(s:String, offset:int, count:int, dt:DateTimeParseRec):Boolean
		    {
			    var validKeyWord:Boolean = false;

			    if (count > kKeyWordLength)
				    return false;

			    // string case must match.  Case insensitivity is not necessary for compliance.
			    var subString:String = s.substr(offset, count);

			    if (count == 3)
			    {
				    for (var x:int = 0; x < kDayAndMonthKeywords.length; ++x)
				    {
					    if (subString == kDayAndMonthKeywords[x])
					    {
						    validKeyWord = true;
						    if (x < 12)  // its a month
							    dt.month = x;
						    else if (x == kUtcKewordPos) // UTC
							    dt.timeZoneOffset = 0;
						    // else its a day or 'GMT'.  Ignore it: GMT is always followed by + or -, and we identify 
						    //  it from there.  day must always be specified numerically, name of day is optional.

						    break;
					    }
				    }
			    }
			    else if (count == 2)
			    {
				    if (subString == "AM")
				    {
					    validKeyWord = (dt.hour <= 12 && dt.hour >=0);
					    if (dt.hour == 12)
						    dt.hour = 0;
				    }
				    else if (subString == "PM")
				    {
					    validKeyWord = (dt.hour <= 12 && dt.hour >=0);
					    if (dt.hour != 12)
						    dt.hour += 12;
				    }
			    }

			    return validKeyWord;
		    }
			
		    // Parses a number out of the string and updates year/month/day/hour/min/timeZoneOffset as
		    //  appropriate (based on whatever has already been parsed).  Assumes that s[i] is an integer
		    //  character.  (broken out into a seperate function from stringToDateDouble() for readability)
		    private static function parseDateNumber(s:String, i:int, c:Number, prevc:Number, dt:DateTimeParseRec):int
		    {
			    var numberIsValid:Boolean = true;

			    // first get number value
			    var numVal:int = int(c - CONFIG::asciiZero);
			    while (i < s.length && (c = s.charCodeAt(i)) >= CONFIG::asciiZero && c <= CONFIG::asciiNine) 
			    {
				    numVal = numVal * 10 + c - CONFIG::asciiZero;
				    i++;
			    }

			    // Supported examples:  "Mon Jan 1 00:00:00 GMT-0800 1900",  '1/1/1999 13:30 PM' 
			    //                      "Mon Jan 1 00:00:00 UTC-0800 1900"

			    // Check for timezone numeric info, which is the only place + or - can occur.
			    //  ala:  'Sun Sept 12 11:11:11 GMT-0900 2004'
			    if (prevc == CONFIG::asciiPlus || prevc == CONFIG::asciiMinus)
			    {
				    if (numVal < 24)
					    numVal = numVal * 60; //GMT-9
				    else
					    numVal = numVal % 100 + numVal / 100 * 60; // GMT-0900

				    if (prevc == CONFIG::asciiPlus) // plus is east of GMT
					    numVal = 0-numVal;

				    if (dt.timeZoneOffset == 0 || dt.timeZoneOffset == -1)
					    dt.timeZoneOffset = numVal;
				    else
					    numberIsValid = false;
				    // note:  do not support ':' in timzone value ala GMT-9:00
			    } 
    			
			    // else check for year value
			    else if (numVal >= 70  ||
					     (prevc == CONFIG::asciiSlash && dt.month >= 0 && dt.day >= 0 && dt.year < 0))
			    {
				    if (dt.year >= 0)
					    numberIsValid = false;
				    else if (c <= CONFIG::asciiSpace || c == CONFIG::asciiComma || c == CONFIG::asciiSlash || i >= s.length)
					    dt.year = numVal < 100 ? numVal + 1900 : numVal;
				    else
					    numberIsValid = false;
			    } 

			    // else check for month or day
			    else if (c == CONFIG::asciiSlash)
			    {
				    if (dt.month < 0)
					    dt.month = numVal-1;
				    else if (dt.day < 0)
					    dt.day = numVal;
				    else
					    numberIsValid = false;
			    } 

			    // else check for time unit
			    else if (c == CONFIG::asciiColon) 
			    {
				    if (dt.hour < 0)
					    dt.hour = numVal;
				    else if (dt.min < 0)
					    dt.min = numVal;
				    else
					    numberIsValid = false;
			    } 

			    // ensure next char is valid before allowing the final cases
			    else if (i < s.length && c != CONFIG::asciiComma && c > CONFIG::asciiSpace && c != CONFIG::asciiMinus) 
			    {
				    numberIsValid = false;
			    } 
    			
			    // check for end of time hh:mm:sec
			    else if (dt.hour >= 0 && dt.min < 0) 
			    {
				    dt.min = numVal;
			    } 
			    else if (dt.min >= 0 && dt.sec < 0) 
			    {
				    dt.sec = numVal;
			    } 

			    // check for end of mm/dd/yy
			    else if (dt.day < 0) 
			    {
				    dt.day = numVal;
			    } 
			    else 
			    {
				    numberIsValid = false;
			    }
			    return numberIsValid ? i : -1;
		    }  


		    private static function stringToDateDouble(s:String):Number
		    {
			    var dt:DateTimeParseRec = new DateTimeParseRec;

			    dt.year = -1;
			    dt.month = -1;
			    dt.day = -1;
			    dt.hour = -1;
			    dt.min = -1;
			    dt.sec = -1;
			    dt.timeZoneOffset = -1;       

			    //  Note:  compliance with ECMAScript 3 only requires that we can parse what our toString() 
			    //  method produces.  We do support some other simple formats just to pass Spidermonkey test 
			    //  suite, however (for instance "1/1/1999 13:30 PM"), but we don't handle timezone keywords
			    //  or instance.

			    var c:Number = 0;
			    var prevc:Number = 0;
			    var i:int = 0;
			    while (i < s.length) 
			    {
				    c = s.charCodeAt(i);
				    i++;

				    // skip whitespace and delimiters (and possibly garbage chars)
				    if (c <= CONFIG::asciiSpace || c == CONFIG::asciiComma || c == CONFIG::asciiMinus) 
				    {
					    if (i < s.length) 
					    {
						    var nextc:Number = s.charCodeAt(i);
						    // if number follows '-' save c in prevc for use in parseDateNumber for detecting GMT offset
						    if (c == CONFIG::asciiMinus && CONFIG::asciiZero <= nextc && nextc <= CONFIG::asciiNine) 
						    {
							    prevc = c;
						    }
					    }
				    }          
    				
				    // remember date and time seperators and/or numeric +- modifiers.
				    else if (c == CONFIG::asciiSlash || c == CONFIG::asciiColon || c == CONFIG::asciiPlus || c == CONFIG::asciiMinus) 
				    {
					    prevc = c;
				    }
    				
				    // parse numeric value. 
				    else if (CONFIG::asciiZero <= c && c <= CONFIG::asciiNine) 
				    {
					    i = parseDateNumber(s, i, c, prevc, dt);
					    if (i < 0)
						    return NaN;
					    prevc = 0;
				    }

				    // parse keyword
				    else 
				    {
					    // walk forward to end of word
					    var st:int = i - 1;
					    while (i < s.length) 
					    {
						    c = s.charCodeAt(i);
						    if (!(( CONFIG::ascii_A <= c && c <= CONFIG::ascii_Z ) || ( CONFIG::ascii_a <= c && c <= CONFIG::ascii_z )))
							    break;
						    i++;
					    }
					    if (i <= st + 1)
						    return NaN;

					    // check keyword substring against known keywords, modify hour/month/timeZoneOffset as appropriate
					    if (parseDateKeyword(s, st, i-st, dt) == false)
						    return NaN;
					    prevc = 0;
				    }
			    }
			    if (dt.year < 0 || dt.month < 0 || dt.day < 0)
				    return NaN;
			    if (dt.sec < 0)
				    dt.sec = 0;
			    if (dt.min < 0)
				    dt.min = 0;
			    if (dt.hour < 0)
				    dt.hour = 0;
			    if (dt.timeZoneOffset == -1) 
			    { 
				    /* no time zone specified, have to use local */
				    return DateFromYMDHMSM(dt.year, dt.month, dt.day, dt.hour, dt.min, dt.sec, 0, false);
			    }
			    else
			    {
				    return DateFromYMDHMSM(dt.year, dt.month, dt.day, dt.hour, dt.min, dt.sec, 0, true) + (dt.timeZoneOffset * CONFIG::kMsecPerMinute);
			    }
		    }
		
		    // ------------------------------

		    nativeHookNS static function callHook(...args):* 
		    {
		        return DateToString(_getDate(), CONFIG::kToString);
		    }

		    public static function UTC(year, month, date=1, hours=0, minutes=0, seconds=0, ms=0, ... rest):Number
		    {
			    return DateFromYMDHMSM(year, month, date, hours, minutes, seconds, ms, true);
		    }
		}

		AS3 function getUTCFullYear():Number	
		{
			return YearFromTime(m_time);
		}

		AS3 function getUTCMonth():Number		
		{
			return MonthFromTime(m_time)
		}

		AS3 function getUTCDate():Number		
		{
			return DateFromTime(m_time);
		}

		AS3 function getUTCDay():Number		
		{
			return WeekDay(m_time)
		}

		AS3 function getUTCHours():Number	
		{
			return HourFromTime(m_time);
		}

		AS3 function getUTCMinutes():Number	
		{ 
			return MinFromTime(m_time);
		}

		AS3 function getUTCSeconds():Number
		{
			return SecFromTime(m_time);
		}

		AS3 function getUTCMilliseconds():Number
		{
			return MsecFromTime(m_time);
		}

		AS3 function getFullYear():Number
		{
			return YearFromTime(LocalTime(m_time));
		}

		AS3 function getMonth():Number
		{
			return MonthFromTime(LocalTime(m_time))
		}

		AS3 function getDate():Number
		{
			return DateFromTime(LocalTime(m_time));
		}

		AS3 function getDay():Number				
		{
		    return WeekDay(LocalTime(m_time))
		}

		AS3 function getHours():Number				
		{
			return HourFromTime(LocalTime(m_time));
		}

		AS3 function getMinutes():Number			
		{
			return MinFromTime(LocalTime(m_time));
		}

		AS3 function getSeconds():Number			
		{
			return SecFromTime(LocalTime(m_time));
		}

		AS3 function getMilliseconds():Number		
		{
			return MsecFromTime(LocalTime(m_time));
		}

		AS3 function getTimezoneOffset():Number		
		{
		    var t:Number = m_time
			return ((t - LocalTime(t)) / CONFIG::kMsecPerMinute);
		}

		AS3 function getTime():Number				
		{
			return m_time
		}

		AS3 function setFullYear(year = void(0), month = void(0), date = void(0)):Number			
		{ return setDateProperty(CONFIG::k_setFullYear, arguments); }
		
		AS3 function setMonth(month = void(0), date = void(0)):Number								
		{ return setDateProperty(CONFIG::k_setMonth, arguments); }
		
		AS3 function setDate(date = void(0)):Number													
		{ return setDateProperty(CONFIG::k_setDate, arguments); }
		
		AS3 function setHours(hour = void(0), min = void(0), sec = void(0), ms = void(0)):Number	
		{ return setDateProperty(CONFIG::k_setHours, arguments); }
		
		AS3 function setMinutes(min = void(0), sec = void(0), ms = void(0)):Number					
		{ return setDateProperty(CONFIG::k_setMinutes, arguments); }
		
		AS3 function setSeconds(sec = void(0), ms = void(0)):Number									
		{ return setDateProperty(CONFIG::k_setSeconds, arguments); }
		
		AS3 function setMilliseconds(ms = void(0)):Number											
		{ return setDateProperty(CONFIG::k_setMilliseconds, arguments); }
		
		AS3 function setUTCFullYear(year = void(0), month = void(0), date = void(0)):Number				
		{ return setDateProperty(-CONFIG::k_setFullYear, arguments); }
		
		AS3 function setUTCMonth(month = void(0), date = void(0)):Number								
		{ return setDateProperty(-CONFIG::k_setMonth, arguments); }
		
		AS3 function setUTCDate(date = void(0)):Number													
		{ return setDateProperty(-CONFIG::k_setDate, arguments); }
		
		AS3 function setUTCHours(hour = void(0), min = void(0), sec = void(0), ms = void(0)):Number		
		{ return setDateProperty(-CONFIG::k_setHours, arguments); }
		
		AS3 function setUTCMinutes(min = void(0), sec = void(0), ms = void(0)):Number					
		{ return setDateProperty(-CONFIG::k_setMinutes, arguments); }
		
		AS3 function setUTCSeconds(sec = void(0), ms = void(0)):Number									
		{ return setDateProperty(-CONFIG::k_setSeconds, arguments); }
		
		AS3 function setUTCMilliseconds(ms = void(0)):Number											
		{ return setDateProperty(-CONFIG::k_setMilliseconds, arguments); }

		AS3 function valueOf():Number				
		{ return m_time; }

		// Date.length = 7 per ES3
		// E262 {ReadOnly, DontDelete, DontEnum }
		public static const length:int = 7

	    prototype.valueOf = function()
	    {
		    var d:Date = this;
		    return d.AS3::valueOf();
	    }
		
		CONFIG::Full
		{
    		AS3 function toString():String
    		{ return DateToString(m_time, CONFIG::kToString); }

    		AS3 function toDateString():String
    		{ return DateToString(m_time, CONFIG::kToDateString); }

    		AS3 function toTimeString():String
    		{ return DateToString(m_time, CONFIG::kToTimeString); }

    		AS3 function toLocaleString():String
    		{ return DateToString(m_time, CONFIG::kToLocaleString); }
		
    		AS3 function toLocaleDateString():String
    		{ return DateToString(m_time, CONFIG::kToLocaleDateString); }
		
    		AS3 function toLocaleTimeString():String
    		{ return DateToString(m_time, CONFIG::kToLocaleTimeString); }

    		AS3 function toUTCString():String
    		{ return DateToString(m_time, CONFIG::kToUTCString); }

		    AS3 function setTime(t = void(0)):Number
		    {
		        m_time = TimeClip(t);
		        return m_time;
		    }
		
		    prototype.setTime = function(t = void(0)):Number
		    {
		        var d:Date = this;
		        d.m_time = TimeClip(t);
		        return d.m_time;
		    }

		    prototype.toString = function():String
		    {
		        var d:Date = this;
		        return DateToString(d.m_time, CONFIG::kToString);
		    }

		    public static function parse(s):Number
		    {
		        return stringToDateDouble(s);
		    }
		
		    prototype.toDateString = function():String
		    {
			    var d:Date = this
			    return d.AS3::toDateString()
		    }

		    prototype.toTimeString = function():String
		    {
			    var d:Date = this
			    return d.AS3::toTimeString()
		    }

		    prototype.toLocaleString = function():String
		    {
			    var d:Date = this
			    return d.AS3::toLocaleString()
		    }

		    prototype.toLocaleDateString = function():String
		    {
			    var d:Date = this
			    return d.AS3::toLocaleDateString()
		    }

	        prototype.toLocaleTimeString = function():String
	        {
		        var d:Date = this
		        return d.AS3::toLocaleTimeString()
	        }

		    prototype.toUTCString = function():String
		    {
			    var d:Date = this
			    return d.AS3::toUTCString()
		    }

		    prototype.getUTCFullYear = function():Number
		    {
			    var d:Date = this
			    return d.AS3::getUTCFullYear()
		    }
		
		    prototype.getUTCMonth = function():Number
		    {
			    var d:Date = this
			    return d.AS3::getUTCMonth()
		    }
		
		    prototype.getUTCDate = function():Number
		    {
			    var d:Date = this
			    return d.AS3::getUTCDate()
		    }
		
		    prototype.getUTCDay = function():Number
		    {
			    var d:Date = this
			    return d.AS3::getUTCDay()
		    }
		
		    prototype.getUTCHours = function():Number
		    {
			    var d:Date = this
			    return d.AS3::getUTCHours()
		    }
		
		    prototype.getUTCMinutes = function():Number
		    {
			    var d:Date = this
			    return d.AS3::getUTCMinutes()
		    }
		
		    prototype.getUTCSeconds = function():Number
		    {
			    var d:Date = this
			    return d.AS3::getUTCSeconds()
		    }
		
		    prototype.getUTCMilliseconds = function():Number
		    {
			    var d:Date = this
			    return d.AS3::getUTCMilliseconds()
		    }
		
		    prototype.getFullYear = function():Number
		    {
			    var d:Date = this
			    return d.AS3::getFullYear()
		    }
		
		    prototype.getMonth = function():Number
		    {
			    var d:Date = this
			    return d.AS3::getMonth()
		    }
		
		    prototype.getDate = function():Number
		    {
			    var d:Date = this
			    return d.AS3::getDate()
		    }
		
		    prototype.getDay = function():Number
		    {
			    var d:Date = this
			    return d.AS3::getDay()
		    }
		
		    prototype.getHours = function():Number
		    {
			    var d:Date = this
			    return d.AS3::getHours()
		    }
		
		    prototype.getMinutes = function():Number
		    {
			    var d:Date = this
			    return d.AS3::getMinutes()
		    }
		
		    prototype.getSeconds = function():Number
		    {
			    var d:Date = this
			    return d.AS3::getSeconds()
		    }
    		
		    prototype.getMilliseconds = function():Number
		    {
			    var d:Date = this
			    return d.AS3::getMilliseconds()
		    }
    		
		    prototype.getTimezoneOffset = function():Number
		    {
			    var d:Date = this
			    return d.AS3::getTimezoneOffset()
		    }
    		
		    prototype.getTime = function():Number
		    {
			    var d:Date = this
			    return d.AS3::getTime()
		    }

		    prototype.setFullYear = function(year = void(0), month = void(0), date = void(0)):Number
		    {
			    var d:Date = this
			    return d.AS3::setFullYear.apply(d, arguments);
		    }
		    
		    prototype.setMonth = function(month = void(0), date = void(0)):Number
		    {
			    var d:Date = this
			    return d.AS3::setMonth.apply(d, arguments);
		    }
		
		    prototype.setDate = function(date = void(0)):Number
		    {
			    var d:Date = this
			    return d.AS3::setDate.apply(d, arguments);
		    }

		    prototype.setHours = function(hour = void(0), min = void(0), sec = void(0), ms = void(0)):Number
		    {
			    var d:Date = this
			    return d.AS3::setHours.apply(d, arguments);
		    }

		    prototype.setMinutes = function(min = void(0), sec = void(0), ms = void(0)):Number
		    {
			    var d:Date = this
			    return d.AS3::setMinutes.apply(d, arguments);
		    }

		    prototype.setSeconds = function(sec = void(0), ms = void(0)):Number
		    {
			    var d:Date = this
			    return d.AS3::setSeconds.apply(d, arguments);
		    }

		    prototype.setMilliseconds = function(ms = void(0)):Number
		    {
			    var d:Date = this
			    return d.AS3::setMilliseconds.apply(d, arguments);
		    }

		    prototype.setUTCFullYear = function(year = void(0), month = void(0), date = void(0)):Number
		    {
			    var d:Date = this
			    return d.AS3::setUTCFullYear.apply(d, arguments);
		    }

	        prototype.setUTCMonth = function(month = void(0), date = void(0)):Number
	        {
		        var d:Date = this
		        return d.AS3::setUTCMonth.apply(d, arguments);
	        }

		    prototype.setUTCDate = function(date = void(0)):Number
		    {
			    var d:Date = this
			    return d.AS3::setUTCDate.apply(d, arguments);
		    }

		    prototype.setUTCHours = function(hour = void(0), min = void(0), sec = void(0), ms = void(0)):Number
		    {
			    var d:Date = this
			    return d.AS3::setUTCHours.apply(d, arguments);
		    }

		    prototype.setUTCMinutes = function(min = void(0), sec = void(0), ms = void(0)):Number
		    {
			    var d:Date = this
			    return d.AS3::setUTCMinutes.apply(d, arguments);
		    }

		    prototype.setUTCSeconds = function(sec = void(0), ms = void(0)):Number
		    {
			    var d:Date = this
			    return d.AS3::setUTCSeconds.apply(d, arguments);
		    }

		    prototype.setUTCMilliseconds = function(ms = void(0)):Number
		    {
			    var d:Date = this
			    return d.AS3::setUTCMilliseconds.apply(d, arguments);
		    }

		    public function get fullYear():Number { return AS3::getFullYear(); }
		    public function set fullYear(value:Number) { AS3::setFullYear(value); }

		    public function get month():Number { return AS3::getMonth(); }
		    public function set month(value:Number) { AS3::setMonth(value); }

		    public function get date():Number { return AS3::getDate(); }
		    public function set date(value:Number) { AS3::setDate(value); }

		    public function get hours():Number { return AS3::getHours(); }
		    public function set hours(value:Number) { AS3::setHours(value); }

		    public function get minutes():Number { return AS3::getMinutes(); }
		    public function set minutes(value:Number) { AS3::setMinutes(value); }

		    public function get seconds():Number { return AS3::getSeconds(); }
		    public function set seconds(value:Number) { AS3::setSeconds(value); }

		    public function get milliseconds():Number { return AS3::getMilliseconds(); }
		    public function set milliseconds(value:Number) { AS3::setMilliseconds(value); }

		    public function get fullYearUTC():Number { return AS3::getUTCFullYear(); }
		    public function set fullYearUTC(value:Number) { AS3::setUTCFullYear(value); }

		    public function get monthUTC():Number { return AS3::getUTCMonth(); }
		    public function set monthUTC(value:Number) { AS3::setUTCMonth(value); }

		    public function get dateUTC():Number { return AS3::getUTCDate(); }
		    public function set dateUTC(value:Number) { AS3::setUTCDate(value); }

		    public function get hoursUTC():Number { return AS3::getUTCHours(); }
		    public function set hoursUTC(value:Number) { AS3::setUTCHours(value); }

		    public function get minutesUTC():Number { return AS3::getUTCMinutes(); }
		    public function set minutesUTC(value:Number) { AS3::setUTCMinutes(value); }

		    public function get secondsUTC():Number { return AS3::getUTCSeconds(); }
		    public function set secondsUTC(value:Number) { AS3::setUTCSeconds(value); }

		    public function get millisecondsUTC():Number { return AS3::getUTCMilliseconds(); }
		    public function set millisecondsUTC(value:Number) { AS3::setUTCMilliseconds(value); }

		    public function get time():Number { return AS3::getTime(); }
		    public function set time(value:Number) { AS3::setTime(value); }

		    public function get timezoneOffset():Number { return AS3::getTimezoneOffset(); }
		    public function get day():Number { return AS3::getDay(); }
		    public function get dayUTC():Number { return AS3::getUTCDay(); }
        }
        
        //public function Date(year = void(0), month = void(0), date = void(0), hours = void(0), minutes = void(0), seconds = void(0), ms = void(0), ...rest)
		// @todo: need to add a way to access args in this manner but still provide for strict-mode arg checking.
		public function Date(...args)
        {
			var argslen:uint = args.length;
			if (argslen === 1) 
			{
				var year:* = args[0];
				var dateAsDouble:Number
				if (CONFIG::Full)
				    dateAsDouble = (year is String) ? stringToDateDouble(year) : Number(year)
				else
				    dateAsDouble = year
				    
				m_time = TimeClip(dateAsDouble);
			}
			else if (argslen !== 0) 
			{
				var num:Array = [ 0, 0, 1, 0, 0, 0, 0 ]; // defaults
				if (argslen > 7)
					argslen = 7;
				for (var i:uint = 0; i < argslen; ++i) 
					num[i] = Number(args[i]);
				m_time = DateFromYMDHMSM(num[0], num[1], num[2], num[3], num[4], num[5], num[6], false);
			} 
			else 
			{
				m_time = _getDate();
			}
		}
        
		// the one and only data member
		private var m_time:Number;

		// These are not part of ECMA-262, and thus we will not be exposing
		// them via the new-style get/set functions (this is provided here
		// just to let you know we didn't overlook them)
		//public function get year():Number { return getYear(); }
		//public function get yearUTC():Number { return getUTCYear(); }	

		// The following older ECMA and/or AS2 functions are not supported since
		// they are not Y2K compliant (only get/set 2 digits)
		// getYear
		// setYear
		// getUTCYear
		// setUTCYear

		_hideproto(prototype);
	}

    CONFIG::Full
	internal class DateTimeParseRec
	{
		public var year:int;
		public var month:int;
		public var day:int;
		public var hour:int;
		public var min:int;
		public var sec:int;
		public var timeZoneOffset:int;
	}
}
