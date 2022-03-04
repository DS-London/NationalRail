module SimpleTree;

import std.stdio;
import std.range;
import std.algorithm;
import std.string;

class XmlNode
{
	string _name;
	string _data;
	XmlNode[] _children;

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

	auto findChildren(string name)
	{
		return filter!(n => n._name == name)(_children);
	}

	string childData(string name)
	{
		auto flt = findChildren(name);

		if( flt.empty ) return "";

		return flt.front._data;
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

		strRet ~= (sClose ~ sCR) ;

		if( _data.length ) strRet ~= (indent ~ sData ~ _data ~ sCR);

		foreach(child; _children)
		{
			strRet ~= child.format(bPlain,indent ~ "  ");
		}

		if(bPlain) strRet ~= (sOpen ~ sEnd ~ _name ~ sClose ~ sCR);

		return strRet;
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

int main()
{
    auto root = new XmlNode("root");
	root.addChild("Level 1").addChild("Level 2","42");

	auto found = drill(root,"Level 1");

	found.addChild("Level 2").addChild("Level 3");

	auto data = found.childData("Level 2");

	writeln(data);

    return 0;
}
