Param(
[string]$SvgFont = $(Read-Host "Indiquer le le chemin de la SvgFont"),
[string]$Color = '#FF0000',
[int]$Size = 256,
[string]$outDirectory = ''
)

$SvgFont = $SvgFont.Trim('"')

if(!(Test-Path $SvgFont)){
    Write-Error "Le chemin de la SvgFont n'est pas valide"
}

if($outDirectory -ne ''){
    if(!(Test-Path $outDirectory -PathType Container)){
        Write-Error "Le chemin de sortie n'est pas valide"
    }
} else {
    $baseDirectory = (gi $SvgFont).Directory.FullName
    $outDirectory = $baseDirectory + '\SvgFont'
    if(!(Test-Path $outDirectory -PathType Container)){
        New-Item -Name $outDirectory -ItemType Directory | Write-Host -ForegroundColor DarkCyan
    }
}

$inkscape = get-command 'C:\Program Files*\Inkscape\inkscape.exe' -ErrorAction Stop

[XML]$SvgFontData = Get-Content $SvgFont

$h = $SvgFontData.svg.defs.font.'font-face'.Attributes['units-per-em'].value
$w = $SvgFontData.svg.defs.font.Attributes['horiz-adv-x'].value
$acent = $SvgFontData.svg.defs.font.'font-face'.Attributes['ascent'].value

[int]$numGliph = 0

[int]$nbElement = $SvgFontData.svg.defs.font.glyph.length
[int]$element = 0

Write-Progress -Activity "convert svgFont to png"

$SvgFontData.svg.defs.font.GetEnumerator() | % {
    
    if($_.Name -eq 'glyph' -and !(!($_.d))){

        $idName = $_.'glyph-name';
        if(!$idName){
            $numGliph = $numGliph + 1
            $idName = 'glyph' + $numGliph;
        }
        $element = $element + 1
        Write-Progress -Activity "convert svgFont to png" -Status "en cours" -CurrentOperation $idName -PercentComplete [System.Math]::min(100,$($element * 100 / $nbElement))


        [XML]$Svg = "<?xml version=`"1.0`" standalone=`"no`"?>`n<svg>`n</svg>";

        $d = $Svg.CreateAttribute('d');
        $d.value = $_.d;
        $fill = $Svg.CreateAttribute('fill');
        $fill.value = $Color;
        $transform = $Svg.CreateAttribute('transform');
        $transform.value = "matrix(1,0,0,-1,0,$acent)";

        $path = $Svg.CreateElement('path');
        $path.Attributes.Append($d) | Out-Null;
        $path.Attributes.Append($fill) | Out-Null;
        $path.Attributes.Append($transform) | Out-Null;

        $id = $Svg.CreateAttribute('id');
        $id.value = $idName;

        $group = $Svg.CreateElement('g');
        $group.Attributes.Append($id) | Out-Null;
        $group.AppendChild($path) | Out-Null;

        $Svg.DocumentElement.AppendChild($group) | Out-Null;

        $xmlns = $Svg.CreateAttribute('xmlns');
        $xmlns.value = "http://www.w3.org/2000/svg"

        $viewBox = $Svg.CreateAttribute('viewBox');
        $viewBox.value = "0 0 $w $h";

        $Svg.svg.Attributes.Append($xmlns) | Out-Null;
        $Svg.svg.Attributes.Append($viewBox) | Out-Null;

        $SvgTmpName = $outDirectory + '\tmp.svg'
        $Svg.Save($SvgTmpName)

        &$inkscape -z -e $($outDirectory + '\' + $idName + '.png') -w $Size -T $SvgTmpName
        Wait-Process inkscape
    
    }
}
