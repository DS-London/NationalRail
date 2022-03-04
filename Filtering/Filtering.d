module Filtering;

import std.stdio;
import std.range;
import std.algorithm;

auto filterNums(int[] vals,int limit)
{
	return filter!(n => n >limit)(vals);
}

int main()
{
    int[] nums = [1,2,3,4,5];

    auto flt3 = filterNums(nums,3);
    auto flt1 = filterNums(nums,1);

    writeln(nums);

    foreach(n;flt3)
    {
        writeln(n);
	}



    return 0;
}
