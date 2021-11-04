unit Main;

interface

uses
  FMX.Forms, System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Variants, FMX.StdCtrls, FMX.Controls, FMX.Edit, FMX.Types,
  FMX.Surfaces, FMX.Controls.Presentation, FMX.Layouts, FMX.ExtCtrls,
  FMX.Objects, FMX.Graphics, System.IOUtils,
  FMX.ListBox, FMX.Colors, FMX.Dialogs;

type
  TfrmMain = class(TForm)
    btnProcess: TButton;
    EditSrcDir: TEdit;
    EditDstDir: TEdit;
    btnSelectSource: TButton;
    btnSelectDestination: TButton;
    Styles: TStyleBook;
    GroupMultiply: TGroupBox;
    Label1: TLabel;
    Label2: TLabel;
    TrackBarBorder: TTrackBar;
    LayoutClient: TLayout;
    LayoutBottom: TLayout;
    GroupSRC: TGroupBox;
    LayoutCenter: TLayout;
    SelectColorBottom: TComboColorBox;
    Label4: TLabel;
    Label3: TLabel;
    SelectColorTop: TComboColorBox;
    GroupDST: TGroupBox;
    LayoutCenterCenter: TLayout;
    btnStop: TButton;
    FastMode: TCheckBox;
    Image1: TImage;
    Image2: TImage;
    procedure btnProcessClick(Sender: TObject);
    procedure btnSelectSourceClick(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure Image1Click(Sender: TObject);
    procedure Image2Click(Sender: TObject);
    procedure TrackBarBorderChange(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure SelectColorTopChange(Sender: TObject);
    procedure btnSelectDestinationClick(Sender: TObject);
    procedure btnStopClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    procedure SingleReplace;
    procedure SetProtectMode(state: boolean);
    { Private declarations }
  public
    dostop: boolean;
    { Public declarations }
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.fmx}

procedure TfrmMain.btnSelectDestinationClick(Sender: TObject);
var
  dir: string;
begin
  if SelectDirectory('Select a directory', '', dir) then
  begin
    EditDstDir.Text := dir;
  end;
end;

procedure TfrmMain.btnSelectSourceClick(Sender: TObject);
var
  dir: string;
begin
  if SelectDirectory('Select a directory', '', dir) then
  begin
    EditSrcDir.Text := dir;

    if EditDstDir.Text.Trim = '' then
      EditDstDir.Text := TPath.Combine(dir, 'dest');
  end;
end;

procedure TfrmMain.btnStopClick(Sender: TObject);
begin
  SetProtectMode(false);
end;

procedure TfrmMain.FormActivate(Sender: TObject);
begin
  SingleReplace;
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  dostop := true;
end;

procedure TfrmMain.FormResize(Sender: TObject);
var
  nw: single;
begin
  nw := LayoutClient.Width / 2;
  if nw > LayoutCenter.Width / 2 then
    nw := nw - LayoutCenter.Width / 2;

  GroupSRC.Width := nw;
  GroupDST.Width := nw;
end;

procedure TfrmMain.Image1Click(Sender: TObject);
var
  Dialog: TOpenDialog;
  fn: string;
begin
  if not TrackBarBorder.Enabled then
    exit;
  Dialog := TOpenDialog.Create(self);
  try
    if Dialog.Execute then
    begin
      fn := Dialog.FileName;
      if FileExists(fn) then
        Image1.Bitmap.LoadFromFile(fn);
    end;
  finally
    Dialog.Free;
  end;
  SingleReplace;
end;

procedure TfrmMain.Image2Click(Sender: TObject);
var
  Dialog: TSaveDialog;
  fn: string;
begin
  if not TrackBarBorder.Enabled then
    exit;
  Dialog := TSaveDialog.Create(self);
  try
    if Dialog.Execute then
    begin
      fn := Dialog.FileName;
      Image1.Bitmap.SaveToFile(fn);
    end;
  finally
    Dialog.Free;
  end;
end;

procedure TfrmMain.SelectColorTopChange(Sender: TObject);
begin
  SingleReplace;
end;

procedure TfrmMain.SingleReplace;
var
  r, g, b: longint;
  r2, g2, b2, a2: longint;
  x, y: longint;
  f: longint;
  bitm: TBitmapSurface;
  ColorTop, ColorBottom: TAlphaColor;
  Color: TAlphaColor;
  Percent: single;
  myBitmap: TBitmap;
  str: TMemoryStream;
begin
  if Image1.Bitmap.IsEmpty then
    exit;

  ColorTop := SelectColorTop.Color;
  ColorBottom := SelectColorBottom.Color;
  Percent := TrackBarBorder.Value / TrackBarBorder.Max; // (0 .. 1)
  myBitmap := TBitmap.Create;
  bitm := TBitmapSurface.Create;
  try
    bitm.Assign(Image1.Bitmap);
    for x := 0 to bitm.Width - 1 do
      for y := 0 to bitm.Height - 1 do
      begin
        r2 := TAlphaColorRec(bitm.Pixels[x, y]).b;
        g2 := TAlphaColorRec(bitm.Pixels[x, y]).g;
        b2 := TAlphaColorRec(bitm.Pixels[x, y]).r;
        a2 := TAlphaColorRec(bitm.Pixels[x, y]).A;
        if (y < (bitm.Height) * Percent) then
        begin
          r := TAlphaColorRec(ColorTop).r;
          g := TAlphaColorRec(ColorTop).g;
          b := TAlphaColorRec(ColorTop).b;
        end
        else
        begin
          r := TAlphaColorRec(ColorBottom).r;
          g := TAlphaColorRec(ColorBottom).g;
          b := TAlphaColorRec(ColorBottom).b;
        end;
        // if a2>125 then
        // showmessage('');
        f := 255 - round(((r2 + g2 + b2) / 3));
        TAlphaColorRec(Color).r := 255 - round((1 - (r / 255)) * f);
        TAlphaColorRec(Color).g := 255 - round((1 - (g / 255)) * f);
        TAlphaColorRec(Color).b := 255 - round((1 - (b / 255)) * f);
        TAlphaColorRec(Color).A := a2;
        bitm.Pixels[x, y] := TAlphaColor(Color);
      end;
    // bitm.
    // Image2.Bitmap.Assign(bitm);
    myBitmap.Assign(bitm);

    str := TMemoryStream.Create;
    try
      myBitmap.SaveToStream(str);
      str.Position := 0;
      Image2.Bitmap.LoadFromStream(str);
    finally
      str.Free;
    end;
  finally
    myBitmap.Free;
    bitm.Free;
  end;
end;

procedure TfrmMain.TrackBarBorderChange(Sender: TObject);
begin
  SingleReplace;
end;

procedure TfrmMain.btnProcessClick(Sender: TObject);
var
  src, dst: string;
  fn, nfn: string;
  files: TArray<string>;
  i: integer;
  percents: double;
begin
  src := EditSrcDir.Text.Trim;
  if (src = '') or not TDirectory.Exists(src) then
  begin
    ShowMessage('Source directory incorrect');
    exit;
  end;

  if EditDstDir.Text.Trim = '' then
    EditDstDir.Text := TPath.Combine(src, 'dest');

  dst := EditDstDir.Text.Trim;

  if not TDirectory.Exists(dst) then
  begin
    TDirectory.CreateDirectory(dst);
  end;

  if not TDirectory.Exists(dst) or (dst = src) then
  begin
    ShowMessage('Destination directory incorrect');
    exit;
  end;

  files := TDirectory.GetFiles(src);

  SetProtectMode(true);

  for i := Low(files) to High(files) do
    if not dostop then
      try
        fn := files[i];
        nfn := TPath.Combine(EditDstDir.Text, TPath.GetFileName(fn));

        Image1.Bitmap.LoadFromFile(fn);
        SingleReplace;
        Image2.Bitmap.SaveToFile(nfn);

        percents := round(100 * (i / Length(files)));
        btnProcess.Text := percents.ToString + '% completed';
        Application.ProcessMessages;
      except
      end;

  btnProcess.Text := 'Process';

  SetProtectMode(false);
end;

procedure TfrmMain.SetProtectMode(state: boolean);
begin
  // set state to true then work in progress
  dostop := not state;
  btnStop.Enabled := state;
  btnProcess.Enabled := not state;
  SelectColorTop.Enabled := not state;
  SelectColorBottom.Enabled := not state;
  TrackBarBorder.Enabled := not state;
  FastMode.Enabled := not state;

  if FastMode.IsChecked then
  begin
    Image1.Visible := not state;
    Image2.Visible := not state;
  end
  else
  begin
    Image1.Visible := Visible;
    Image2.Visible := Visible;
  end
end;

end.
