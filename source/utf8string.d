module utf8string;

import std.stdio : writeln;
import std.stdio : writefln;


/** */
struct UTF8String
{
    // string
    //   .length
    //   .ptr
    string s;
    alias s this;


    mixin UTF8StringInputRange!();
    mixin UTF8StringForwardRange!();
    mixin UTF8StringBidirectionalRange!();


/+
    /** Prev char position in UTF8 string */
    size_t nextPosReverse( size_t pos )
    {
        // (x & 0xc0) == 0x80
        //
        // UTF8:
        //   00000000-0000007F 1 byte
        //   00000080-000007FF 2
        //   00000800-0000FFFF 3 
        //   00010000-0010FFFF 4
        // 
        // Byte bits Pattern
        //   1   7   0xxxxxxx
        //   2   11  110xxxxx 10xxxxxx
        //   3   16  1110xxxx 10xxxxxx 10xxxxxx
        //   4   21  11110xxx 10xxxxxx 10xxxxxx 10xxxxxx

        ubyte prev1 = s[ pos - 1 ];

        // 0xxx_xxxx: valid char
        if ( ( prev1 & 0b1000_0000 ) == 0b0000_0000 )  
        {
            return pos - 1;  // OK: 1-Byte code
        }
        else // 10xx_xxxx: last part of code
        if ( ( prev1 & 0b1100_0000 ) == 0b1000_0000 )  
        {
            // read 1 more
            ubyte prev2 = s[ pos - 2 ];

            // 110x_xxxx: prefix of 2-Byte code
            if ( ( prev2 & 0b1110_0000 ) == 0b1100_0000 )  
            {
                return pos - 2;  // OK: 2-Byte code
            }
            else // 10xx_xxxx: part of code
            if ( ( prev2 & 0b1100_0000 ) == 0b1000_0000 )  
            {
                ubyte prev3 = s[ pos - 3 ];

                // 1110_xxxx: 3-Byte code
                if ( ( prev3 & 0b1111_0000 ) == 0b1110_0000 )  
                {
                    return pos - 3;  // OK: 3-Byte code
                }
                else  // 10xx_xxxx: part of code
                if ( ( prev3 & 0b1100_0000 ) == 0b1000_0000 )  
                {
                    ubyte prev4 = s[ pos - 4 ];

                    // 1111_0xxx: 4-Byte code
                    if ( ( prev4 & 0b1111_1000 ) == 0b1111_0000 )  
                    {
                        return pos - 4;  // OK: 4-Byte code
                    }
                    else  // invalid
                    {
                        // FAIL
                    }
                }
                else  // invalid
                {
                    // FAIL
                }
            }
            else  // invalid
            {
                // FAIL
            }
        }
        else  // invalid
        {
            // FAIL
        }

        // FAIL
        return -1;
    }

    ///** Prev char position in UTF8 string */
    //size_t nextPosReverseG( size_t pos )
    //{
    //    import std.utf   : encode;
    //    import std.uni   : Grapheme;

    //    // Get Prev UTF8 Symbol
    //    auto  gs = s[ 0 .. pos ].Grapheme;
    //    dchar dc = gs[ gs.length - 1 ];

    //    char[4] buff;
    //    auto l = encode( buff, dc );

    //    return pos - l;
    //}


    /** Next char position in UTF8 string */
    size_t nextPos( size_t pos )
    {
        import std.utf : decode;

        size_t l;

        // Get Next UTF8 Symbol
        s[ pos .. $ ].decode( l );

        return pos + l;
    }
    +/
}


/** InputRange */
mixin template UTF8StringInputRange()
{
    // ASCII :   1 byte
    // UTF8  : 1-4 byte
    alias E = string;


    /** */
    E front()
    {
        import std.utf : decode;

        size_t l;

        dchar dc = s.decode( l );

        return s[ 0 .. l ];
    }


    /** */
    E moveFront()
    {
        return "";
    }


    /** */
    void popFront()
    {
        s = s[ front.length .. $ ];
    }


    /** */
    bool empty()
    {
        return s.length == 0;
    }


    /** */
    int opApply( scope int delegate( E ) dg )
    {
        int result = 0;

        while ( !empty )
        {
            result = dg( front );

            if ( result )
            {
                break;
            }

            popFront();
        }

        return result;
    }


    /** */
    int opApply( scope int delegate( size_t, E ) dg )
    {
        int result = 0;
        int i      = 0;

        while ( !empty )
        {
            result = dg( i, front );

            if ( result )
            {
                break;
            }

            popFront();

            i += 1;
        }

        return result;
    }
}


/** ForwardRange */
mixin template UTF8StringForwardRange()
{
    alias E = string;


   /** */
   typeof( this ) save()
   {
       return this;
   }
}


/** BidirectionalRange */
mixin template UTF8StringBidirectionalRange()
{
    alias E = string;


    /** */
    typeof( this ) save()
    {
       return this;
    }


    /** */
    @property 
    E back()
    {
        auto end = ( cast( char* ) s.ptr ) + s.length;
        auto newPtr = nextPosReverse( end );
        auto l = end - newPtr;
        return s[ $ - l .. $ ];
    }


    /** */
    E moveBack()
    {
        return "";
    }


    /** */
    void popBack()
    {
        auto end = ( cast( char* ) s.ptr ) + s.length;
        auto newPtr = nextPosReverse( end );
        auto l = end - newPtr;
        s.length -= l;
    }


    /** */
    int opApplyReverse( scope int delegate( E ) dg )
    {
        int result = 0;

        while ( !empty )
        {
            result = dg( back );

            if ( result )
            {
                break;
            }

            popBack();
        }

        return result;
    }


    /** */
    int opApplyReverse( scope int delegate( size_t, E ) dg )
    {
        int    result = 0;
        size_t i      = length;

        while ( !empty )
        {
            i -= back.length;

            result = dg( i, back );

            if ( result )
            {
                break;
            }

            popBack();
        }

        return result;
    }
}


///** RandomAccessFinite */
//struct UTF8StringRandomAccessFinite
//{
//    UTF8StringBidirectionalRange s;

//    alias E = string;


//    /** */
//    @property UTF8StringRandomAccessFinite!E save()
//    {
//        //
//    }


//    /** */
//    E opIndex( size_t pos )
//    {
//        return "";
//    }


//    /** */
//    E moveAt( size_t )
//    {
//        return "";
//    }


//    /** */
//    @property size_t length()
//    {
//        return s.length;
//    }


//    /** */
//    alias opDollar = length;


//    /** */
//    UTF8StringRandomAccessFinite!E opSlice( size_t a , size_t b )
//    {
//        //return UTF8StringRandomAccessFinite!E( s[ a .. b ] );
//    }
//}


///** */
//struct UTF8StringRandomAccessInfinite
//{
//    UTF8StringForwardRange s;   

//    alias E = string;


//    /** */
//    E moveAt( size_t pos )
//    {
//        return "";
//    }    


//    /** */
//    @property UTF8StringRandomAccessInfinite!E save()
//    {
//        //return "";
//    }    


//    /** */
//    E opIndex( size_t pos )
//    {
//        return "";
//    }
//}


/+
version ( D_SIMD )
{
    pragma( msg, "SIMD UTF8 decder enabled." );

    // SIMD decoder
    ubyte* decode( size_t length, ubyte* s, ulong* c )
    {
        // Byte bits Pattern
        //   1   7   0xxxxxxx
        //   2   11  110xxxxx 10xxxxxx
        //   3   16  1110xxxx 10xxxxxx 10xxxxxx
        //   4   21  11110xxx 10xxxxxx 10xxxxxx 10xxxxxx

        // Read 4 Bytes into the 32-bit register
        //   Detect Way: 1 | 2 | 3 | 4 -Byte
        //   some like: 10000000 00000000 00000000 00000000 == 00000000 00000000 00000000 00000000 is 1
        //              11100000 00000000 00000000 00000000 == 11000000 00000000 00000000 00000000 is 2
        //              11110000 00000000 00000000 00000000 == 11100000 00000000 00000000 00000000 is 3
        //              11111000 00000000 00000000 00000000 == 11110000 00000000 00000000 00000000 is 4
        // Mask char bits
        //   some like: 00000111 00111111 00111111 00111111
        // Merge bits
        //   some like: 00000000 00011111 11111111 11111111

        import core.simd;

        // Read 4 Bytes into the 32-bit register
        uint eax = cast( uint ) s[ 0 .. 4 ].ptr;

        // Detect Way: 1 | 2 | 3 | 4 -Byte
        // eax  
        // _128_bit_reg =
        //   [
        //      0b10000000_00000000_00000000_00000000, //  32
        //      0b11100000_11000000_00000000_00000000, //  64
        //      0b11110000_11000000_11000000_00000000, //  96
        //      0b11111000_11000000_11000000_11000000  // 128 bit
        //   ]
        //
        // mov!4 _128_bit_reg_2, eax
        //
        // and _128_bit_reg, _128_bit_reg_2
        // 
        // _128_bit_reg_3 =
        //   [
        //      0b00000000_00000000_00000000_00000000, //  32
        //      0b11000000_10000000_00000000_00000000, //  64
        //      0b11100000_10000000_10000000_00000000, //  96
        //      0b11110000_10000000_10000000_10000000  // 128 bit
        //   ]
        //
        // cmp _128_bit_reg2, _128_bit_reg_3
        //
        // Result is: [ 1, 0, 0, 0 ] or [ 0, 1, 0, 0 ] or [ 0, 0, 1, 0 ] or [ 0, 0, 0, 1 ]
        //
        // Shift bits
        //   0b00000111_00111111_00111111_00111111
        //                                00111111  
        //                                00111111  // << 0
        //
        //                       00111111
        //              00001111_11000000           // << 6
        //
        //              00111111
        //     00000011_11110000                    // << 4
        //
        //    00000111
        //    00011100                              // << 2
        //
        //                                00111111  // << 0  
        //                       00001111_11000000  // << 6
        //              00000011_11110000_00000000  // << 4
        //              00011100_00000000_00000000  // << 2
        //              00011111_11111111_11111111  // result
        //
        //                                00111111
        //
        // Another
        //            A        B        C        D
        //   0b00000111_00111111_00111111_00111111
        //   mov XX, A
        //   XX << 6
        //   XX & B     // 9 bits
        //   
        //   mov YY, C
        //   YY << 6
        //   YY & D     // 12 bits
        //   
        //   mov ZZZZ, XX
        //   ZZZZ << 12
        //   ZZZZ & YY  // 21 bits
        //
        //
        //if ( ( eax & 0b10000000_00000000_00000000_00000000 ) == 0b00000000_00000000_00000000_00000000 ) goto L_1_BYTES;
        //if ( ( eax & 0b11100000_11000000_00000000_00000000 ) == 0b11000000_10000000_00000000_00000000 ) goto L_2_BYTES;
        //if ( ( eax & 0b11110000_11000000_11000000_00000000 ) == 0b11100000_10000000_10000000_00000000 ) goto L_3_BYTES;
        //if ( ( eax & 0b11111000_11000000_11000000_11000000 ) == 0b11110000_10000000_10000000_10000000 ) goto L_4_BYTES;
        //L_INVALID:
        //    return 0;

        //L_1_BYTES:
        //    *c = UPPER_BYTE( eax );
        //    s += 1;
        //    return s;
        //L_2_BYTES:
        //    // Mask char bits
        //    s += 2;
        //    return s;
        //L_3_BYTES:
        //    s += 3;
        //    return s;
        //L_4_BYTES:
        //    s += 4;
        //    return s;
    }
}
else
version ( Win32 )
{
    pragma( msg, "Windows 32 UTF8 decder enabled." );
}
else
version ( Win64 )
{
    pragma( msg, "Windows 64 UTF8 decder enabled." );

    // Windows decoder
    char* decode( char* s, ref dchar dc )
    {
        import core.sys.windows.windows;

        int l = MultiByteToWideChar( CP_UTF8, MB_COMPOSITE, s, -1, cast( wchar* ) &dc, dc.sizeof );

        s += l;

        return s;
    }
}
else
version ( linux )
{
    pragma( msg, "Linux UTF8 decder enabled." );
}
else
+/
version ( Win64 )
{
    pragma( msg, "Default UTF8 decder enabled." );

    // Primitive decoding
    char* decodeStabe( char* s, ref dchar dc )
    {
        char* next;

        // 1-Byte: 0xxxxxxx
        if ( s[0] < 0b1000_0000 ) 
        {
            dc = s[0];
            next = s + 1;
        } 
        else  
        // 2-Byte: 110xxxxx 10xxxxxx
        if ( ( s[0] & 0b1110_0000 ) == 0b1100_0000 )
        {
            dc = ( cast( dchar ) ( s[0] & 0b0001_1111 ) <<  6 ) |
                 ( cast( dchar ) ( s[1] & 0b0011_1111 ) <<  0 );
            next = s + 2;
        } 
        else  
        // 3-Byte: 1110xxxx 10xxxxxx 10xxxxxx
        if ( ( s[0] & 0b1111_0000 ) == 0b1110_0000 ) 
        {
            dc = ( cast( dchar ) ( s[0] & 0b0000_1111 ) << 12 ) |
                 ( cast( dchar ) ( s[1] & 0b0011_1111 ) <<  6 ) |
                 ( cast( dchar ) ( s[2] & 0b0011_1111 ) <<  0 );
            next = s + 3;
        } 
        else  
        // 4-Byte: 11110xxx 10xxxxxx 10xxxxxx 10xxxxxx
        if ( ( s[0] & 0b1111_1000 ) == 0b1111_0000 && ( s[0] <= 0b1111_0100 ) ) 
        {
            dc = ( cast( dchar ) ( s[0] & 0b0000_0111 ) << 18 ) |
                 ( cast( dchar ) ( s[1] & 0b0011_1111 ) << 12 ) |
                 ( cast( dchar ) ( s[2] & 0b0011_1111 ) <<  6 ) |
                 ( cast( dchar ) ( s[3] & 0b0011_1111 ) <<  0 );
            next = s + 4;
        } 
        else 
        // invalid
        {
            dc = '�';     // invalid
            next = s + 1;  // skip this byte
        }

        
        if ( dc >= 0b1101_1000_0000_0000 && dc <= 0b1101_1111_1111_1111 )
        {
            dc = '�';  // surrogate half
        }

        return next;
    }


    // Primitive decoding
    char* decode( char* s, ref dchar dc )
    {
        byte  a = *s;    // register A
        byte  b;         // register B
        short ax;        // register AX
        short bx;        // register EB
        int   eax;       // register EAX

        // 1-Byte: 0xxxxxxx
        if ( a > 0 )  // highest bit is 0. May be Sign flag (SF) == 0 ( after arithmetic )
        {
            dc = a;
            s += 1;   // set pointer to next symbol
            return s;
        } 

        // 2-Byte: 110xxxxx 10xxxxxx
        // 3-Byte: 1110xxxx 10xxxxxx 10xxxxxx
        // 4-Byte: 11110xxx 10xxxxxx 10xxxxxx 10xxxxxx
        a <<= 2;       // 110xxxxx => 0xxxxx..
        if ( a > 0 )   // highest bit is 0. May be Sign flag (SF) == 0 ( after arithmetic )
        {
            ax = a;    // register AX
            ax <<= 4;  // 00000000_0xxxxx.. => 000xxxxx_00000000
            s  += 1;   // next
            b  = *s;   // read byte into the register B
            b  &= 0b00111111;  // 10xxxxxx => 00xxxxxx
            ax |= b;

            dc = ax;
            s += 1;    // set pointer to next symbol

            return s;
        } 

        // 3-Byte: 1110xxxx 10xxxxxx 10xxxxxx
        a <<= 1;
        if ( a > 0 )   // highest bit is 0. May be Sign flag (SF) == 0 ( after arithmetic )
        {
            ax = a;    // register AX
            ax <<= 9;  // 00000000_0xxxx... => xxxx0000_00000000

            s  += 1;   // next
            b  = *s;   // read byte into the register B
            b  &= 0b00111111;  // 10xxxxxx => 00xxxxxx
            bx = b;
            bx <<= 6;  // 00000000_10xxxxxx => 0010xxxx_xx000000
            ax |= bx;  // xxxx0000_00000000 | 0000xxxx_xx000000 => xxxxxxxx_xx000000

            s  +=1;    // next
            b  = *s;   // read byte into the register B
            b  &= 0b00111111;  // 10xxxxxx => 00xxxxxx
            ax |= b;   // xxxxxxxx_xx000000 | 00xxxxxx => xxxxxxxx_xxxxxxxx

            dc = ax;
            s += 1;    // set pointer to next symbol

            return s;
        } 

        // 4-Byte: 11110xxx 10xxxxxx 10xxxxxx 10xxxxxx
        a <<= 1;
        if ( a > 0 )   // highest bit is 0. May be Sign flag (SF) == 0 ( after arithmetic )
        {
            ax = a;    // register AX
            ax <<= 8;  // 00000000_0xxx.... => 0xxx0000_00000000

            s  += 1;   // next
            b  = *s;   // read byte into the register EB
            b  &= 0b00111111;  // 10xxxxxx => 00xxxxxx
            bx = b;
            bx <<= 6;  // 00000000_10xxxxxx => 0010xxxx_xx000000
            ax |= bx;  // xxxx0000_00000000 | 0000xxxx_xx000000 => xxxxxxxx_xx000000

            s  += 1;   // next
            b  = *s;   // register B
            b  &= 0b00111111;  // 10xxxxxx => 00xxxxxx
            ax |= b;   // xxxxxxxx_xx000000 | 00xxxxxx => xxxxxxxx_xxxxxxxx

            eax = ax;
            eax <<= 6; // 00000000_xxxxxxxx_xxxxxxxx => 00xxxxxx_xxxxxxxx_xx000000
            s   +=1;   // next
            b   = *s;  // register B
            b   &= 0b00111111;  // 10xxxxxx => 00xxxxxx
            eax |= b;  // 00xxxxxx_xxxxxxxx_xx000000 | 00xxxxxx => 00xxxxxx_xxxxxxxx_xxxxxxxx

            dc = eax;
            s += 1;    // set pointer to next symbol

            return s;
        } 

        // invalid
        {
            dc = '�';  // invalid
            s += 1;     // skip this byte
            return s;
        }
    }


    /** Decode UTF8 string in reverse direction */
    char* decodeReverse( char* s, ref dchar dc )
    {
        s = nextPosReverse( s );
        decode( s, dc );
        return s;
    }


    /** */
    char* nextPosReverse( char* s )
    {
        s -= 1;
        byte a = *s;  // register A

        // 1-Byte: 0xxxxxxx
        if ( a > 0 )  // highest bit is 0. May be Sign flag (SF) == 0 ( after arithmetic )
        {
            return s;
        } 

        // 2-Byte: 110xxxxx 10xxxxxx
        s -= 1;
        a = *s;
        if ( ( a & 0b0100_0000 ) != 0 )
        {
            return s;
        } 

        // 3-Byte: 1110xxxx 10xxxxxx 10xxxxxx
        s -= 1;
        a = *s;
        if ( ( a & 0b0100_0000 ) != 0 ) 
        {
            return s;
        } 

        // 4-Byte: 11110xxx 10xxxxxx 10xxxxxx 10xxxxxx
        s -= 1;
        a = *s;
        if ( ( a & 0b0100_0000 ) != 0 ) 
        {
            return s;
        } 

        // invalid
        {
            s += 4 - 1;    // restore position. skip 1 byte
            return s;
        }
    }


    /** */
    char* nextPos( char* s )
    {
        byte a = *s;  // register A

        // 1-Byte: 0xxxxxxx
        if ( a > 0 )  // highest bit is 0. May be Sign flag (SF) == 0 ( after arithmetic )
        {
            s += 1;
            return s;
        } 

        // 2-Byte: 110xxxxx 10xxxxxx
        a <<= 2;
        if ( a > 0 )   // highest bit is 0. May be Sign flag (SF) == 0 ( after arithmetic )
        {
            s += 2;
            return s;
        } 

        // 3-Byte: 1110xxxx 10xxxxxx 10xxxxxx
        a <<= 1;
        if ( a > 0 )   // highest bit is 0. May be Sign flag (SF) == 0 ( after arithmetic )
        {
            s += 3;
            return s;
        } 

        // 4-Byte: 11110xxx 10xxxxxx 10xxxxxx 10xxxxxx
        a <<= 1;
        if ( a > 0 )  // highest bit is 0. May be Sign flag (SF) == 0 ( after arithmetic )
        {
            s += 4;
            return s;
        } 

        // invalid
        {
            s += 1;  // skip 1 byte
            return s;
        }
    }
}


///
unittest
{
    string src;

    // ASCII
    src = "Abc";

    auto utf8String = UTF8String( src );

    foreach ( i, s; utf8String )
    {
        switch ( i )
        {
            case 0: assert( s == "A" ); break;
            case 1: assert( s == "b" ); break;
            case 2: assert( s == "c" ); break;
            default: assert( 0 );
        }
    }

    // Unicode Forward
    src = "ᐅᐅᐅ";

    auto utf8String2 = UTF8String( src );

    foreach ( i, s; utf8String2 )
    {
        switch ( i )
        {
            case 0: assert( s == "ᐅ" ); break;
            case 1: assert( s == "ᐅ" ); break;
            case 2: assert( s == "ᐅ" ); break;
            default: assert( 0 );
        }
    }

    // Unicode Backward
    src = "ᐅᐅᐅ";

    auto utf8String3 = UTF8String( src );

    foreach_reverse ( i, s; utf8String3 )
    {
        switch ( i )
        {
            case 0: assert( s == "ᐅ" ); break;
            case 3: assert( s == "ᐅ" ); break;
            case 6: assert( s == "ᐅ" ); break;
            default: assert( 0 );
        }
    }

    // decode UTF8 1-Byte symbols
    src = "Abc";
    dchar dc;
    char* ptr;
    ptr = cast( char* ) src.ptr;
    ptr = decode( ptr, dc );
    assert( dc == 'A' );
    assert( ptr == src.ptr + 1 );
    ptr = decode( ptr, dc );
    assert( dc == 'b' );
    assert( ptr == src.ptr + 2 );

    // decode 2-Byte symbols
    src = "Жук";
    ptr = cast( char* ) src.ptr;
    ptr = decode( ptr, dc );
    assert( dc == 'Ж' );
    assert( ptr == src.ptr + 2 );
    ptr = decode( ptr, dc );
    assert( dc == 'у' );
    assert( ptr == src.ptr + 4 );

    // decode 3-Byte symbols
    src = "ᐅᐅᐅ";
    ptr = cast( char* ) src.ptr;
    ptr = decode( ptr, dc );
    assert( dc == 'ᐅ' );
    assert( ptr == src.ptr + 3 );
    ptr = decode( ptr, dc );
    assert( dc == 'ᐅ' );
    assert( ptr == src.ptr + 6 );

    // nextPosReverse. 1-Byte
    src = "Abc";
    ptr = cast( char* ) src.ptr;
    ptr = nextPosReverse( ptr + 2 );  // from 'c'
    assert( *ptr == 'b' );
    assert( ptr == src.ptr + 1 );
    ptr = nextPosReverse( ptr );
    assert( *ptr == 'A' );
    assert( ptr == src.ptr );

    // nextPosReverse. 2-Byte
    src = "Жук";
    ptr = cast( char* ) src.ptr;
    ptr = nextPosReverse( ptr + 4 );  // from 'к'
    assert( ptr[ 0 .. 2 ] == [ 0xD1, 0x83 ] );  // 'у'
    assert( ptr == src.ptr + 2 );
    ptr = nextPosReverse( ptr );
    assert( ptr[ 0 .. 2 ] == [ 0xD0, 0x96 ] );  // 'Ж'
    assert( ptr == src.ptr );

    // nextPosReverse. 3-Byte
    src = "ᐅᐅᐅ";
    ptr = cast( char* ) src.ptr;
    ptr = nextPosReverse( ptr + 6 );
    assert( dc == 'ᐅ' );
    assert( ptr == src.ptr + 3 );
    ptr = nextPosReverse( ptr );
    assert( dc == 'ᐅ' );
    assert( ptr == src.ptr );

    // nextPos. 1-Byte
    src = "Abc";
    ptr = cast( char* ) src.ptr;
    assert( *ptr == 'A' );
    ptr = nextPos( ptr );
    assert( *ptr == 'b' );
    assert( ptr == src.ptr + 1 );
    ptr = nextPos( ptr );
    assert( *ptr == 'c' );
    assert( ptr == src.ptr + 2 );

    // nextPos. 2-Byte
    src = "Жук";
    ptr = cast( char* ) src.ptr;
    assert( ptr[ 0 .. 2 ] == [ 0xD0, 0x96 ] );  // 'Ж'
    ptr = nextPos( ptr );
    assert( ptr[ 0 .. 2 ] == [ 0xD1, 0x83 ] );  // 'у'
    assert( ptr == src.ptr + 2 );
    ptr = nextPos( ptr );
    assert( ptr[ 0 .. 2 ] == [ 0xD0, 0xBA ] );  // 'к'
    assert( ptr == src.ptr + 4 );

    // nextPos. 3-Byte
    src = "ᐅᐅᐅ";
    ptr = cast( char* ) src.ptr;
    ptr = nextPos( ptr );
    assert( dc == 'ᐅ' );
    assert( ptr == src.ptr + 3 );
    ptr = nextPos( ptr );
    assert( dc == 'ᐅ' );
    assert( ptr == src.ptr + 6 );

    // decodeReverse. 1-Byte
    src = "Abc";
    ptr = cast( char* ) src.ptr;
    ptr = decodeReverse( ptr + 2, dc );  // at "c"
    assert( dc == 'b' );
    assert( ptr == src.ptr + 1 );
    ptr = decodeReverse( ptr, dc );
    assert( dc == 'A' );
    assert( ptr == src.ptr );

    // decodeReverse. 2-Byte
    src = "Жук";
    ptr = cast( char* ) src.ptr;
    ptr = decodeReverse( ptr + 4, dc );  // at "к"
    assert( dc == 'у' );
    assert( ptr == src.ptr + 2 );
    ptr = decodeReverse( ptr, dc );
    assert( dc == 'Ж' );
    assert( ptr == src.ptr );

    // decodeReverse. 3-Byte
    src = "ᐅᐅᐅ";
    ptr = cast( char* ) src.ptr;
    ptr = decodeReverse( ptr + 6, dc );
    assert( dc == 'ᐅ' );
    assert( ptr == src.ptr + 3 );
    ptr = decodeReverse( ptr, dc );
    assert( dc == 'ᐅ' );
    assert( ptr == src.ptr );
}
