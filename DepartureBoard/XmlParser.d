module XmlParser;

import std.stdio;
import std.range;
import std.string;

struct XmlAttribute
{
	string _name;
	string _value;
}

class XmlNode
{
	string _name;
	string _data;
	XmlNode[] _children;
	XmlAttribute[] _attributes;

	XmlNode _parent = null;

	this(string name, string data="", XmlNode parent = null)
	{
		_name = name;
		_data = data;
		_parent = parent;
	}

	XmlNode addChild(string name,string data = "")
	{
		_children ~= new XmlNode(name,data,this);

		return _children[$-1]; 
	}

	auto addAttribute(string name, string value)
	{
		_attributes ~= XmlAttribute(name,value);
	}

	void clear() 
	{
		_data = "";
		_children = null;
		_attributes = null;
		_parent = null;
	}

	string format(bool bPlain = true, string indent = "")
	{
		string sOpen;
		string sClose;
		string sEnd;
		string sCR = "\n";
		string sData = "  ";

		if( bPlain )
		{
			sOpen = "<";
			sClose = ">";
			sEnd = "/";
			sCR = "";
			indent = "";
			sData = "";
		}
		
		string strRet = indent ~ sOpen ~ _name;

		foreach(ref attr; _attributes)
		{
			strRet ~= ( " " ~ attr._name ~ "=" ~ attr._value); 
		}
		strRet ~= (sClose ~ sCR) ;
			
		if( _data.length ) strRet ~= (indent ~ sData ~ _data ~ sCR);

		foreach(ref child; _children)
		{
			strRet ~= child.format(bPlain,indent ~ "  ");
		}
		
		if(bPlain) strRet ~= (sOpen ~ sEnd ~ _name ~ sClose ~ sCR);

		return strRet;
	}

	auto findChildren(string name)
	{
		string s = name;

		XmlNode[] ret;
		foreach(n;_children)
		{
			if( n._name == name )
			{
				ret ~= n;
			}
		}

		return ret;
	}

	string childData(string name)
	{	
		auto children = this.findChildren(name);

		if(children.empty) return "";
			
		return children.front._data;
	}
}

XmlNode drill(XmlNode node, string name)
{
	auto flt = node.findChildren(name);

	if( flt.empty ) return null;
	
	return flt.front;
}

XmlNode drill(A...)(XmlNode node, string name, A a)
{
	auto n = drill(node,name);

	if(n) return drill(n,a);

	return null;
}

class NodeBuilder
{
	static const char tagOpen = '<';
	static const char tagClose = '>';
	static const char tagEnd = '/';
	
	XmlNode _root = null;
	XmlNode _current = null;

	void processData(string data)
	{
		_current._data = data;
	}

	void processTag(string tag)
	{
		switch(tag[1])
		{
			case '?':
				break;
			case tagEnd: //Leave node
				_current = _current._parent;
				break;
			default: //New node	
				auto parts = split(tag[1 .. $-1],' ');

				if( _current )
				{
					_current = _current.addChild(parts[0]);
				}
				else
				{
					_root = new XmlNode(parts[0]);
					_current = _root;
				}

				//Attributes
				if (parts.length > 1)
				{
					foreach(part; parts[1..$])
					{
						auto attparts = split(part,'=');
						_current._attributes ~= XmlAttribute(attparts[0],attparts[1]);
					}
				}
		}
	}

	XmlNode buildNode(string strXml)
	{
		_root = null;
		_current = null;
		
		string data;
		while(! strXml.empty )
		{	
			dchar c = strXml.front;
			strXml.popFront;
			
			if( c== tagOpen)
			{
				if(data.length > 0) 
				{	
					processData(data);
					data = "";
				}
					
				string tag;
				tag ~= c;

				c = strXml.front;
				strXml.popFront;

				while (c && (c != tagClose))
				{
					tag ~= c;
					c = strXml.front;
					strXml.popFront;
				}

				processTag(tag ~ tagClose);
				continue;
			}

			data ~= c;		
		}

		return _root;
	}
}



