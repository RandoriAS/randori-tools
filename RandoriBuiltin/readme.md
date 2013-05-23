How to generate a builtin.swc
=============

Edit the build.xml first and change this element:

**&lt;property name="FLEX_HOME" value="C:/Program Files (x86)/Adobe/Adobe Flash Builder 4.6/sdks/4.9.1/" /&gt;**

to reflect the location of your local Flex SDK.

Then run "ant" on a commandline.

After the builtin.swc is created, opened the SWC with a zip or Rar editor and extract this file:
catalog.xml

Open his file in a text editor and find the two XML elements that look like this (usually at the bottom of the file):

**&lt;script name="flash/display/Sprite" mod="1369328922099" signatureChecksum="3914207921" &gt;

&lt;def id="flash.display:Sprite" /&gt; 
&lt;dep id="AS3" type="n" /&gt; 
&lt;dep id="Object" type="i" /&gt; 
&lt;/script&gt;
&lt;script name="_043da8af9560b800626e55e447d48647698342236e3501548f6c26b82157ef1a_flash_display_Sprite" mod="1369328980902" signatureChecksum="1125283663" &gt;
&lt;def id="_043da8af9560b800626e55e447d48647698342236e3501548f6c26b82157ef1a_flash_display_Sprite" /&gt; 
&lt;dep id="AS3" type="n" /&gt; 
&lt;dep id="flash.display:Sprite" type="i" /&gt; 
&lt;/script&gt;**

Delete this entire block of text, save the file and replace it inside the builtin.swc file.

Et voila, you have yourself a Randori specific builtin.swc!

=============

By the way, to add extra classes to the builtin.swc, open the build.xml and find this element:

**&lt;include-sources dir="${basedir}/randori" includes="builtin.as Math.as Date.as RegExp.as"/&gt;**

Add any .as files you want to include in the 'includes' attribute.
