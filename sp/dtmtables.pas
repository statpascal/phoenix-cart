unit dtmtables;

interface

function getDtmKqk (strongKing, weakKing, piece: integer): uint8;
//function getDtmKrk (strongKing, weakKing, piece: integer): uint8;


implementation

uses resources;

{$ifdef ti99}

function lookup_kqk_0 (offs: integer): integer;
    procedure kqk_data_0; external '../resources/dtm_kqk_0.dat';
    var
        dtm_kqk_0: TDtmFoldedSegment absolute kqk_data_0;
    begin
        result := dtm_kqk_0 [offs]
    end;

function lookup_kqk_1 (offs: integer): integer;
    procedure kqk_data_1; external '../resources/dtm_kqk_1.dat';
    var
        dtm_kqk_1: TDtmFoldedSegment absolute kqk_data_1;
    begin
        result := dtm_kqk_1 [offs]
    end;

function lookup_kqk_2 (offs: integer): integer;
    procedure kqk_data_2; external '../resources/dtm_kqk_2.dat';
    var
        dtm_kqk_2: TDtmFoldedSegment absolute kqk_data_2;
    begin
        result := dtm_kqk_2 [offs]
    end;

function lookup_kqk_3 (offs: integer): integer;
    procedure kqk_data_3; external '../resources/dtm_kqk_3.dat';
    var
        dtm_kqk_3: TDtmFoldedSegment absolute kqk_data_3;
    begin
        result := dtm_kqk_3 [offs]
    end;

function lookup_kqk_4 (offs: integer): integer;
    procedure kqk_data_4; external '../resources/dtm_kqk_4.dat';
    var
        dtm_kqk_4: TDtmFoldedSegment absolute kqk_data_4;
    begin
        result := dtm_kqk_4 [offs]
    end;

function lookup_kqk_5 (offs: integer): integer;
    procedure kqk_data_5; external '../resources/dtm_kqk_5.dat';
    var
        dtm_kqk_5: TDtmFoldedSegment absolute kqk_data_5;
    begin
        result := dtm_kqk_5 [offs]
    end;

function lookup_kqk_6 (offs: integer): integer;
    procedure kqk_data_6; external '../resources/dtm_kqk_6.dat';
    var
        dtm_kqk_6: TDtmFoldedSegment absolute kqk_data_6;
    begin
        result := dtm_kqk_6 [offs]
    end;

function lookup_kqk_7 (offs: integer): integer;
    procedure kqk_data_7; external '../resources/dtm_kqk_7.dat';
    var
        dtm_kqk_7: TDtmFoldedSegment absolute kqk_data_7;
    begin
        result := dtm_kqk_7 [offs]
    end;

function lookup_kqk_8 (offs: integer): integer;
    procedure kqk_data_8; external '../resources/dtm_kqk_8.dat';
    var
        dtm_kqk_8: TDtmFoldedSegment absolute kqk_data_8;
    begin
        result := dtm_kqk_8 [offs]
    end;

function lookup_kqk_9 (offs: integer): integer;
    procedure kqk_data_9; external '../resources/dtm_kqk_9.dat';
    var
        dtm_kqk_9: TDtmFoldedSegment absolute kqk_data_9;
    begin
        result := dtm_kqk_9 [offs]
    end;

function lookup_kqk (idx, offs: integer): integer;
    begin
        case idx of
            0:
                lookup_kqk := lookup_kqk_0 (offs);
            1:
                lookup_kqk := lookup_kqk_1 (offs);
            2:
                lookup_kqk := lookup_kqk_2 (offs);
            3:
                lookup_kqk := lookup_kqk_3 (offs);
            4:
                lookup_kqk := lookup_kqk_4 (offs);
            5:
                lookup_kqk := lookup_kqk_5 (offs);
            6:
                lookup_kqk := lookup_kqk_6 (offs);
            7:
                lookup_kqk := lookup_kqk_7 (offs);
            8:
                lookup_kqk := lookup_kqk_8 (offs);
            9:
                lookup_kqk := lookup_kqk_9 (offs)
        end
    end;
    
{$endif}

{$ifdef fpc}

function lookup_kqk (idx, offs: integer): integer;
    begin
        lookup_kqk := dtmKQKFolded [idx, offs]
    end;
    
{$endif}    

function symTab (t, s: integer): integer;
    var
        r, f: integer;
    begin
        r := s div 8;
        f := s mod 8;
        case t of
            0:
                symTab := s;
            1:
                symTab := 8 * r       + 7 - f;		// flip files
            2:
                symTab := 8 * (7 - r) + f;		// flit ranks
            3:
                symTab := 8 * (7 - r) + 7 - f;		// rot 180
            4:
                symTab := 8 * f       + r;		// diag
            5:
                symTab := 8 * (7 - f) + 7 - r;	 	// anti diag
            6:
                symTab := 8 * f       + 7 - r;		// rot 90
            7:
                symTab := 8 * (7 - f) + r		// rot 270
        end
    end;
    
var 
    canonT, canonIdx: array [0..63] of uint8;
    
procedure initCanon;
    var
        nCanon, s, t, best, bt, im: integer;
    begin
        for s := 0 to 63 do
            begin
                best := 100;
                bt := 0;
                for t := 0 to 7 do
                    begin
                        im := symTab (t, s);
                        if im < best then
                            begin
                                best := im;
                                bt := t
                            end
                    end;
                canonT [s] := t
            end;
            
        for s := 0 to 63 do
            canonIdx [s] := 255;
        nCanon := 0;
        for s := 0 to 63 do
            if symTab (canonT [s], s) = s then
                begin
                    canonIdx [s] := nCanon;
                    inc (nCanon)
                end
    end;
    
function getDtmKqk (strongKing, weakKing, piece: integer): uint8;
    var 
        t: integer;
    begin
        t := canonT [strongKing];
        result := lookup_kqk (canonIdx [symTab (t, strongKing)], symTab (t, weakKing) * 64 + symTab (t, piece))
    end;
    
begin
    initCanon
end.
