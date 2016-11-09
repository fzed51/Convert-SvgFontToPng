Param(
$WebFont = $(Read-Host "Indiquer le le chemin de la webFont"),
$svgName = $(Read-Host "Indiquer le nom du fichier de sortie")
)

$WebFont = $WebFont.Trim('"')

if(!(Test-Path $WebFont)){
    Write-Error "Le chemin de la webFont n'est pas valide"
}

[xml]$WebFontData = Get-Content $WebFont
[xml]$Svg = @'
<?xml version="1.0" standalone="no"?>
<svg>
</svg>
'@

[int]$numGliph = 0

$WebFontData.svg.defs.font.GetEnumerator() | % {
    if($_.Name -eq 'glyph' -and !(!($_.d))){
    
        $d = $Svg.CreateAttribute('d')
        $d.value = $_.d

        $path = $Svg.CreateElement('path')
        $path.Attributes.Append($d)

        $id = $Svg.CreateAttribute('id')
        $id.value = 'glyph' + $numGliph

        $group = $Svg.CreateElement('g')
        $group.Attributes.Append($id)
        $group.AppendChild($path)

        $Svg.DocumentElement.AppendChild($group)

        $numGliph = $numGliph + 1
    
    }
}

$xmlns = $Svg.CreateAttribute('xmlns')
$xmlns.value = "http://www.w3.org/2000/svg"

$h = $WebFontData.svg.defs.font.'font-face'.Attributes['units-per-em'].value
$w = $WebFontData.svg.defs.font.Attributes['horiz-adv-x'].value
$viewBox = $Svg.CreateAttribute('viewBox')
$viewBox.value = "0 0 $w $h"

$Svg.svg.Attributes.Append($xmlns)
$Svg.svg.Attributes.Append($viewBox)

$directory = (gi $WebFont).Directory.FullName

$Svg.Save($directory + '\' + $svgName + '.svg')

<#
 # Utilisation de Inkscape en ligne de commande pour exporter un svg en png
 #
 # $inkscape = get-command 'C:\Program Files*\Inkscape\inkscape.exe'
 # &$inkscape -z -e $pngName -w 128 -T $svgName
 #>

