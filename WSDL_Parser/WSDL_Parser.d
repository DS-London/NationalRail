module WSDL_Parser;

import XmlParser;

import std.stdio;
import std.conv;
import std.string;
import std.file;

int main()
{
	string strXml;

	foreach(entry; dirEntries("","*.wsdl",SpanMode.shallow))
	{
		auto f = File(entry.name, "r");

		char[] buf;
		while (f.readln(buf))
			strXml ~= chomp(to!string(buf)).strip();	
		
		auto builder = new NodeBuilder;
		auto node = builder.buildNode(strXml);

		writeln("\n",entry.name);	
		writeln(node.format(false));	
	}


	





    return 0;
}
