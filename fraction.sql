create or replace and compile java source named "org/quinto/math/Fraction" as
package org.quinto.math;

import java.util.ArrayList;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class Fraction implements Comparable
{
    private static final Pattern DOUBLE_MINUS_PATTERN = Pattern.compile( "--" );
    private static final Pattern PLUS_MINUS_PATTERN = Pattern.compile( "\\+-" );
    private static final Pattern SPACE_PATTERN = Pattern.compile( "\\p{Space}" );
    private static final Pattern FLOAT_NUMBER_PATTERN = Pattern.compile( "(\\d++)\\.(\\d++)" );
    private long top;
    private long bottom;
    private Integer hash = null;

    public Fraction()
    {
        this( 0 );
    }

    public Fraction( long top )
    {
        this.top = top;
        bottom = 1;
    }

    public Fraction( long top, long bottom )
    {
        this.top = top;
        this.bottom = bottom;
        shorten();
    }

    public long getBottom()
    {
        return bottom;
    }

    public long getTop()
    {
        return top;
    }

    public double doubleValue()
    {
        return ( double )top / bottom;
    }

    public String toString()
    {
        return top + "/" + bottom;
    }

    public String toStringAfterDivision()
    {
        return top + "*" + bottom;
    }

    private void shorten()
    {
        if ( bottom == 0 ) top = top > 0 ? 1 : top < 0 ? -1 : 0;
        else if ( top == 0 ) bottom = 1;
        else
        {
            long gcd = gcd( top, bottom );
            top /= gcd;
            bottom /= gcd;
            if ( bottom < 0 )
            {
                bottom = -bottom;
                top = -top;
            }
        }
    }

    public Object clone()
    {
        return new Fraction( top, bottom );
    }

    public boolean equals( Object obj )
    {
        if ( obj == null ) return false;
        if ( obj instanceof Fraction )
        {
            Fraction rd = ( Fraction )obj;
            return top == rd.top && bottom == rd.bottom;
        }
        if ( obj instanceof Number )
        {
            Number n = ( Number )obj;
            return n.doubleValue() == doubleValue();
        }
        return false;
    }

    public int compareTo( Object obj )
    {
        if ( obj == null ) return 1;
        if ( obj instanceof Fraction )
        {
            Fraction rd = ( Fraction )obj;
            return Double.compare( doubleValue(), rd.doubleValue() );
        }
        if ( obj instanceof Number )
        {
            Number n = ( Number )obj;
            return Double.compare( doubleValue(), n.doubleValue() );
        }
        return 0;
    }

    public int hashCode()
    {
        if ( hash == null ) hash = new Integer( ( int )( top + bottom ) );
        return hash.intValue();
    }

    public static Fraction multiply( Fraction a, Fraction b )
    {
        if ( a == null || b == null ) return null;
        return new Fraction( a.top * b.top, a.bottom * b.bottom );
    }

    public static Fraction divide( Fraction a, Fraction b )
    {
        if ( a == null || b == null ) return null;
        return new Fraction( a.top * b.bottom, a.bottom * b.top );
    }

    public static Fraction minus( Fraction a, Fraction b )
    {
        if ( a == null || b == null ) return null;
        return new Fraction( a.top * b.bottom - a.bottom * b.top, a.bottom * b.bottom );
    }

    public static Fraction plus( Fraction a, Fraction b )
    {
        if ( a == null || b == null ) return null;
        return new Fraction( a.top * b.bottom + a.bottom * b.top, a.bottom * b.bottom );
    }

    public static Fraction minus( Fraction a )
    {
        if ( a == null ) return null;
        return new Fraction( -a.top, a.bottom );
    }

    public static Fraction reverse( Fraction a )
    {
        if ( a == null ) return null;
        return new Fraction( a.bottom, a.top );
    }

    public static long gcd( long a, long b )
    {
        if ( a == 0 || b == 0 ) return 1;
        if ( a < 0 ) a = -a;
        if ( b < 0 ) b = -b;
        while ( b > 0 )
        {
            long c = a % b;
            a = b;
            b = c;
        }
        return a;
    }

    public static long lcm( long a, long b )
    {
        return Math.abs( a * b ) / gcd( a, b );
    }

    private static String replace( String s, int start, int end, String t )
    {
        StringBuffer sb = new StringBuffer( s.substring( 0, start ) );
        sb.append( t );
        sb.append( s.substring( end + 1 ) );
        return sb.toString();
    }

    public static Double calculate( String expression )
    {
        Fraction ret = eval( expression );
		if ( ret == null ) return null;
		return new Double( ret.doubleValue() );
    }

    public static Fraction eval( String expression )
    {
        if ( expression == null ) return null;
        expression = SPACE_PATTERN.matcher( expression ).replaceAll( "" );
        expression = expression.replace( ',', '.' );
        Matcher floatMatcher = FLOAT_NUMBER_PATTERN.matcher( expression );
        int start = 0;
        while ( floatMatcher.find( start ) )
        {
            start = floatMatcher.end();
            if ( floatMatcher.groupCount() >= 2 )
            {
                String integralString = floatMatcher.group( 1 );
                long integral = Long.parseLong( integralString );
                String fractionalString = floatMatcher.group( 2 );
                long fractional = Long.parseLong( fractionalString );
                int pow = fractionalString.length();
                long fraction = 1;
                for ( int i = 0; i < pow; i++ ) fraction *= 10;
                Fraction rd = new Fraction( integral * fraction + fractional, fraction );
                String representation = rd.toString();
                StringBuffer sb = new StringBuffer( representation.length() + 2 );
                sb.append( '(' );
                sb.append( representation );
                sb.append( ')' );
                expression = floatMatcher.replaceFirst( sb.toString() );
            }
            floatMatcher.reset( expression );
        }
        int idx = expression.indexOf( '(' );
        while ( idx >= 0 )
        {
            int idx3 = expression.indexOf( ')', idx + 1 );
            if ( idx3 < 0 ) return null;
            int idx2 = expression.indexOf( '(', idx + 1 );
            if ( idx2 >= 0 && idx3 > idx2 )
            {
                idx = idx2;
                continue;
            }
            Fraction rd = evalNoBrackets( expression.substring( idx + 1, idx3 ) );
            boolean afterDivision = idx > 0 && expression.charAt( idx - 1 ) == '/';
            expression = replace( expression, idx, idx3, afterDivision ? rd.toStringAfterDivision() : rd.toString() );
            idx = expression.indexOf( '(' );
        }
        return evalNoBrackets( expression );
    }

    private static Fraction evalNoBrackets( String expression )
    {
        while ( expression.startsWith( "--" ) ) expression = expression.substring( 2 );
        expression = DOUBLE_MINUS_PATTERN.matcher( expression ).replaceAll( "+" );
        expression = PLUS_MINUS_PATTERN.matcher( expression ).replaceAll( "-" );
        int length = expression.length();
        StringBuffer sb = new StringBuffer();
        ArrayList mds = new ArrayList();
        ArrayList ops = new ArrayList();
        boolean prevCharWasDigit = false;
        for ( int i = 0; i < length; i++ )
        {
            char c = expression.charAt( i );
            if ( c == '+' || ( prevCharWasDigit && c == '-' ) )
            {
                if ( sb.length() == 0 ) return null;
                mds.add( sb.toString() );
                sb = new StringBuffer();
                ops.add( new Character( c ) );
            }
            else
            {
                sb.append( c );
                prevCharWasDigit = Character.isDigit( c );
            }
        }
        if ( sb.length() == 0 ) return null;
        mds.add( sb.toString() );
        Fraction ret = evalMultiplyAndDivide( ( String )mds.get( 0 ) );
        for ( int i = 1; i < mds.size(); i++ )
        {
            Fraction rd = evalMultiplyAndDivide( ( String )mds.get( i ) );
            ret = ( ( Character )ops.get( i - 1 ) ).charValue() == '-' ? Fraction.minus( ret, rd ) : Fraction.plus( ret, rd );
        }
        return ret;
    }

    private static Fraction evalMultiplyAndDivide( String expression )
    {
        int length = expression.length();
        int idx = expression.indexOf( '*' );
        int idx2 = expression.indexOf( '/' );
        idx = Math.min( idx < 0 ? length : idx, idx2 < 0 ? length : idx2 );
        String firstNumber = expression.substring( 0, idx );
        long number;
        try
        {
            number = Long.parseLong( firstNumber );
        }
        catch ( NumberFormatException e )
        {
            return null;
        }
        Fraction ret = new Fraction( number );
        if ( idx == length ) return ret;
        StringBuffer sb = new StringBuffer();
        char op = expression.charAt( idx );
        for ( int i = idx + 1; i < length; i++ )
        {
            char c = expression.charAt( i );
            if ( c == '/' || c == '*' )
            {
                if ( sb.length() == 0 ) return null;
                try
                {
                    number = Long.parseLong( sb.toString() );
                }
                catch ( NumberFormatException e )
                {
                    return null;
                }
                sb = new StringBuffer();
                Fraction rd = new Fraction( number );
                ret = op == '/' ? Fraction.divide( ret, rd ) : Fraction.multiply( ret, rd );
                op = c;
            }
            else sb.append( c );
        }
        if ( sb.length() == 0 ) return null;
        try
        {
            number = Long.parseLong( sb.toString() );
        }
        catch ( NumberFormatException e )
        {
            return null;
        }
        Fraction rd = new Fraction( number );
        ret = op == '/' ? Fraction.divide( ret, rd ) : Fraction.multiply( ret, rd );
        return ret;
    }
}
/
