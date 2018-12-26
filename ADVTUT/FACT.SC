main(n)
{
        print fact(n);
        print "\n";
}

fact(n)
{
        if ( n == "0" ) return "1";
        return n * fact(n - "1");
}
