
unit samsutil;

interface


(* initialize the sams card and verify card is present
   returns 0 for absent, 1 for <= 1mb and 2 for > 1mb *)

function samsInit: integer;

(* returns the number of pages available 
   sizecode 1: <= 1mb, 2: > 1mb *)

procedure samsSize (sizeCode: integer; var pageNums: integer);


(* read/save data to sams pages up to maximum card capacity
   rwcode : 1=save, 2=read
   startpage is the starting page for the save operation. 
   subsequent pages will be automatically assigned if needed
   datasize can be obtained by sizeof(data)
   offset is the number of bytes from the start of the page
   data is a packed array of byte *)

const 
    dataOpsWrite =   1;
    dataOpsRead =   2;

procedure dataOps (rwcode, startPage, dataSize, offset: integer; var data);
//procedure dataOps (rwcode: integer; var startPage, dataSize, offset: integer; var data);


implementation

uses vdp;
// provides setCRUBit

const 
    SamsCRUAddr =   $1e00;
    SamsRegs =   16;
    SamsPageSize =   4096;

function swap (n: integer): integer;
// TODO:  make compiler intrinsic
begin
    swap := (n shr 8) or (n and $ff) shl 8
end;

procedure samsCardOn;

var 
    cruAddr: integer;
begin
    for cruAddr := $10 to $1f do
        setCRUBit (cruAddr shl 8, false);
    setCRUBit (SamsCRUAddr, true);
end;

function samsInit: integer;

var 
    reg: integer;
begin
    samsCardOn;
    for reg := 0 to pred (SamsRegs) do
        memW [$4000 div 2 + reg] := swap (reg);

    if memW [$401e div 2] <> $0f00 then
        samsInit := 0
    else
        begin
            memW [$401e div 2] := $0102;
            samsInit := 1 + ord (memW [$401e div 2] = $0102);
            memW [$401e div 2] :=  $0f00
        end;
    setCRUBit (SamsCRUAddr, false)
end;

procedure samsSize (sizeCode: integer; var pageNums: integer);

const 
    testValue =   $ffff;
    SamsReg2 =   $4004 div 2;
    testAddr =   $2000 div 2;

var 
    savedMem: integer;
    newPage: boolean;
begin
    samsCardOn;
    setCRUBit (SamsCRUAddr + 2, true);
    // turn mapping on
    savedMem := memW [testAddr];

    memW [testAddr] := testValue;
    pageNums := 16;
    repeat
        memW [SamsReg2] := swap (pageNums + 2);
        newPage := memW [testAddr] <> testValue;
        if newPage then
            inc (pageNums, pageNums)
    until not newPage;

    memW [SamsReg2] := $0200;
    memW [testAddr] := savedMem;

    setCRUBit (SamsCRUAddr + 2, false);
    // turn mapping off
    setCRUBit (SamsCRUAddr, false)
end;

var 
    log: text;


procedure dataOps (rwcode, startPage, dataSize, offset: integer; var data);

const 
    SamsReg2 =   $4004 div 2;

type 
    arrtype =   array [0..MaxInt] of uint8;

var 
    bytes, done: integer;
    //        p, q: ^integer;
begin
    //        p := addr (rwcode) + (-1);
    //        q := p + 6;

//        writeln (log, rwcode, ' P: ', startPage, ' O: ', offset:4, ' S: ', dataSize:4, ' C: ', (q^ - $6000) div 2, ':', hexstr (p^));
    samsCardOn;
    setCRUBit (SamsCRUAddr + 2, true);
    // turn mapping on
    done := 0;
    while dataSize > 0 do
        begin
            memW [SamsReg2] := swap (startPage);
            bytes := max (0, min (SamsPageSize - offset, dataSize));
            if rwcode = dataOpsWrite then
                moveWord (arrtype (data) [done], memB [$2000 + offset], bytes div 2)
            else
                moveWord (memB [$2000 + offset], arrtype (data) [done], bytes div 2);
            dec (dataSize, bytes);
            inc (done, bytes);
            offset := 0;
            inc (startPage)
        end;
    memW [SamsReg2] := $0200;
    setCRUBit (SamsCRUAddr + 2, false);
    // turn mapping off
    setCRUBit (SamsCRUAddr, false)
end;



(*
procedure dataOps (rwcode: integer; var startPage, dataSize, offset: integer; var data); assembler;
        lwpi    >8320
        mov     @>8314, r10     // copy stack pointer from Pascal runtime workspace
        
        mov     @data,r4        //get pointer to data array
        mov     @offset,r3        //get pointer to page offset
        mov     @dataSize,r2        //get pointer to number of bytes to transfer
        mov     @startpage,r1        //get pointer to starting page

        mov     *r2,r7          //save byte number to transfer
        li      r6,>4004        //starting sams register (memory >2000)
        li      r12,>1e00       //cru address of sams card
        sbo     0               //turn card on
        li      r5,>2000        //base memory address
        a       *r3,r5          //apply byte offset
        mov     *r3,r0          //store offset in byte counter at start
        mov     *r10,r3         //get r/w code
        sbo     1               //turn mapper on
nxtpage swpb    *r1
        mov     *r1,*r6         //assign page to sams register
        swpb    *r1
rwops   ci      r3,1            //is it a write operation?
        jne     getops
saveops mov     *r4+,*r5+       //save 2 bytes at a time (word)
        jmp     contops
getops  mov     *r5+,*r4+       //get 2 bytes at a time
contops dect    r7
        jle     opsdone         //no more data
        inct    r0
        ci      r0,4096         //are we past 4k of data?
        jlt     rwops
        inc     *r1             //next page number
        clr     r0
        li      r5,>2000
        jmp     nxtpage         //continue data ops
opsdone li      r1,>0200        //restore sams register to original page
        mov     r1,@>4004
        sbz     1               //turn mapper off
        sbz     0               //turn off sams card

        lwpi    >8300
end;
*)

end.
