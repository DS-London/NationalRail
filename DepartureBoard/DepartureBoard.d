module Win32D;

import std.stdio;
import std.exception;
import std.conv;
import core.sys.windows.windows;
import core.sys.windows.wininet;
import std.string;

import HttpRequest;
import LiveBoards;

int main()
{
	immutable string strUrl = "https://lite.realtime.nationalrail.co.uk/OpenLDBWS/ldb9.asmx";	

	auto requester = new HttpRequester(strUrl);
	auto board = new DepBoardWithDetails("VIC",20);
	
	bool b = execute(requester,board);
	
	int width = 55;

	string title = "Live Departure board for " ~ board._location._name;
	
	writeln(rightJustify(leftJustify(title,width - ((width - title.length)/2),' '),width,' '));	
	writeln(leftJustify("",width,'='));

	foreach(service;board._services)
	{
		string header = leftJustify(service._std ~ " " ~ service._destination._name,40,' ');
		header ~= (rightJustify(service._etd,10,' ') ~ 
							rightJustify(service._platform.length > 0 ? service._platform : "-",5,' '));
		writeln(header);
	}

	


    return 0;
}
