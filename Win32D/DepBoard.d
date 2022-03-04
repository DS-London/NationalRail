module DepBoard;

import XmlParser;
import std.conv;
import std.stdio;
import std.string;

immutable string token  = "f7cf5ccd-6c41-42dc-881b-77331f9e9149";

interface Request
{
	string header();
	XmlNode data();

	bool processResponse(XmlNode nodeResponse);
}

struct Location
{
	string _name;
	string _crs;
};

struct Operator
{
	string _name;
	string _code;
};

struct CallingPoint
{
	Location _location;
	string _st;
	string _et;
};

class Service
{
	string _std;
	string _etd;
	Operator _operator;
	string _type;
	string _id;
	Location _origin;
	Location _destination;
	uint _length;
	string _platform;
	CallingPoint[] _callingPoints;

	this(string std, string etd, Operator operator,	string type, string id, Location origin, Location destination, uint len,string platform)
	{
		_std = std;
		_etd = etd;
		_operator = operator;
		_type = type;
		_id = id;
		_origin = origin;
		_destination = destination;
		_length = len;
		_platform = platform;
	}
};

class DepBoardWithDetails : Request
{
	string _crs;
	uint _numServices;
	uint _start;
	uint _end;

	string _token = "";

	Location _location;
	Service[] _services;
	
	this(string crs,uint numServices = 10, uint start =0, uint end = 120)
	{
		_crs = crs;
		_numServices = numServices;
		_start = start;
		_end = end;

		_location._crs = crs;
	}

	string header()
	{
		return "Content-Type: text/xml;charset=UTF-8";
	}

	XmlNode data()
	{
		
		
		auto node = new XmlNode("soap:Envelope");
		node.addAttribute("xmlns:ldb", "\"http://thalesgroup.com/RTTI/2016-02-16/ldb/\"");
		node.addAttribute("xmlns:soap", "\"http://www.w3.org/2003/05/soap-envelope\"");
		node.addAttribute("xmlns:typ", "\"http://thalesgroup.com/RTTI/2013-11-28/Token/types\"");
		node.addChild("soap:Header").addChild("typ:AccessToken").addChild("typ:TokenValue",token);

		auto n = node.addChild("soap:Body").addChild("ldb:GetDepBoardWithDetailsRequest");
		n.addChild("ldb:crs",_crs);
		n.addChild("ldb:numRows",to!string(_numServices));
		n.addChild("ldb:timeOffset",to!string(_start));
		n.addChild("ldb:timeWindow",to!string(_end));

		return node;
	}

	bool processResponse(XmlNode nodeResponse)
	{
		string str = nodeResponse.childData("soap:Body");

		auto nodeResult = drill(nodeResponse,"soap:Body",
											 "GetDepBoardWithDetailsResponse",
											 "GetStationBoardResult");
		if(nodeResult)
		{
			_location._name = nodeResult.childData("lt4:locationName");

			auto services = drill(nodeResult,"lt5:trainServices");

			foreach( nodeService; services.findChildren("lt5:service"))
			{
				auto origin = drill(nodeService,"lt5:origin","lt4:location");
				auto destination = drill(nodeService, "lt5:destination", "lt4:location");

				auto std = nodeService.childData("lt4:std");
				auto etd = nodeService.childData("lt4:etd");
				auto operator = nodeService.childData("lt4:operator");
				auto opCode = nodeService.childData("lt4:operatorCode");
				auto servType = nodeService.childData("lt4:serviceType");
				auto servId = nodeService.childData("lt4:serviceId");

				auto origName = origin.childData("lt4:locationName");
				auto origCrs = origin.childData("lt4:crs");

				auto destName = destination.childData("lt4:locationName");
				auto destCrs = destination.childData("lt4:crs");

				auto len = nodeService.childData("lt4:length");
				uint uiLen = len.length > 0 ? to!uint(len) : 0; 

				auto platform = nodeService.childData("lt4:platform");

				_services ~= new Service(	std,
											etd,
											Operator(operator, opCode),
											servType,
											servId,
											Location(origName, origCrs),
											Location(destName, destCrs),
											uiLen,
											platform );

				auto svc = _services[$-1];
				auto callingPoints = drill(nodeService,"lt5:subsequentCallingPoints","lt4:callingPointList");
				foreach( nodeCp; callingPoints.findChildren("lt4:callingPoint"))
				{
					svc._callingPoints ~= CallingPoint(Location(nodeCp.childData("lt4:locationName"), nodeCp.childData("lt4:crs")),
													   nodeCp.childData("lt4:st"),nodeCp.childData("lt4:et"));
				}

			}

			return true;
		}

		return false;
	}
}