package methods
{
	
	import flash.utils.*;
	
	/**
	 * Tries to convert weird or possibly invalid HTML into valid XML.
	 * Pass the unwashed HTML to the slurp method to clean it up, or toXML
	 * method if you just want some XML to work with.
	 */
	public function toXML(value:*):XML
	{
		
		if(value is XML) return value as XML;
		
		XML.prettyPrinting = false;
		XML.prettyIndent = 0;
		XML.ignoreWhitespace = false;
		
		value = stripComments(value);
		
		try
		{
			//Maybe our string can be easily converted to XML?
			return new XML(trim(value));
		}
		catch(e:Error)
		{
			try
			{
				//But maybe he's just missing a root node?
				return new XML('<body>' + trim(value) + '</body>');
			}
			catch(e:Error)
			{
				//Nope, too optimistic. Slurp 'em up.
				try
				{
					// Try without a root node first.
					return new XML(slurp(value));
				}
				catch(e:Error)
				{
					// Try one last time with a root node.
					try {
						return new XML('<body>' + slurp(value) + '</body>');
					} catch(e:Error) {
					}
				}
			}
		}
		
		return null;
	}
}

import flash.events.Event;
import flash.events.EventDispatcher;
import flash.html.HTMLLoader;
import flash.utils.getDefinitionByName;

internal function stripComments(input:String):String
{
	return input.replace(/<!--(.*?)-->/g, '');
}

/**
 * Slurp your soup. Do some translation on self-terminating nodes
 * before and after slurpage, because the browser doesn't understand
 * self-terminating nodes and it passes back invalid XML but potentially
 * valid HTML.
 */
internal function slurp(tags:String):String
{
	// Replace self terminating nodes with open/close pairs because
	// self-terminating nodes aren't valid in HTML
	// 
	// <tag property="value"/> to <tag property="value"></tag>
	tags = tags.replace(/<[^>\S]*([^>\s|br|hr|img]+)([^>]*)\/[^>\S]*>/g, '<$1$2></$1>');
	
	// Parse the HTML into XHTML with the browser or AIR's webkit engine.
	tags = soup(tags);
	
	// Convert any open tags back to self-terminating nodes.
	tags = tags.replace(/<(hr|br|img)(.*?)>/g, '<$1$2/>');
	
	return trim(tags);
}

/**
 * @private
 * Attempts to parse the input malformed XML tags with the browser
 * through an ExternalInterface call.
 */
internal function soup(tags:String):String
{
	try
	{
		const htmlLoader:HTMLLoader = new HTMLLoader();
		const html:String = '<body>\
			<script type="text/javascript">\
			window.soup = function(tags)\
			{\
			var div = document.createElement("div");\
			div.innerHTML = tags;\
			return div.innerHTML;\
			}\
			</script>\
			</body>';
		var handleComplete:Function = function(event:Event):void
		{
			(event.target as EventDispatcher).removeEventListener(Event.COMPLETE, handleComplete);
			const loader:HTMLLoader = event.target as HTMLLoader;
			var xml:String = loader.window.soup();
			trace(xml);
		}
		htmlLoader.addEventListener(Event.COMPLETE, handleComplete);
		htmlLoader.loadString(html);
	}
	catch(e:Error)
	{
		return tags;
	}
	
	return tags;
}

/**
 * Trims out the excess white space between XML nodes before parsing,
 * but we still want to respect at least one white space between nodes.
 * This is a feature of HTML.
 *
 * TODO: This will have to be tweaked to take into account the
 * difference between sibling block-level nodes (Divs and Ps) and
 * sibling inline elements (like Spans). Spaces are not respected
 * between block-level elements, but are trimmed to one space between
 * inline elements.
 */
internal function trim(input:String):String
{
	return input.
		replace(/\n|\r|\t/g, '').
		replace(/(<\/?\w+((\s+\w+(\s*=\s*(?:".*?"|'.*?'|[^'">\s]+))?)+\s*|\s*)\/?>)(\s+)(<\/?\w+((\s+\w+(\s*=\s*(?:".*?"|'.*?'|[^'">\s]+))?)+\s*|\s*)\/?>)/g, '$1$6').
		replace(/(<\/?\w+((\s+\w+(\s*=\s*(?:".*?"|'.*?'|[^'">\s]+))?)+\s*|\s*)\/?>)(\s+)(<\/?\w+((\s+\w+(\s*=\s*(?:".*?"|'.*?'|[^'">\s]+))?)+\s*|\s*)\/?>)/g, '$1$6');
}