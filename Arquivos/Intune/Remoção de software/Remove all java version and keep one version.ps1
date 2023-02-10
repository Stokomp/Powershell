#Remocao Java
#v1.0

#Variaveis - Versoes que nao serao excluidas

$Java1_4 = "1.4.2.0"
$Java1_5 = "1.5.0.220"
$Java6_1 = "6.0.130"
$Java6_3 = "6.0.300"
$Java6_4 = "6.0.450"
$Java7 = "7.0.800"
$Java7_0 = "7.0.150"
$Java7_1 = "7.0.170"
$java7_2 = "7.0.250"
$Java7_5 = "7.0.510"
$Java7_6 = "7.0.670"
$Java7_7 = "7.0.710"
$Java7_9 = "7.0.790"
$Java8 = "8.0.3010.9"


#Essa linha ira listar todas as versoes do Java no computador
Get-WmiObject -Class Win32_Product | Where-Object {$_.Name -match "Java"}

#Node ira aplicar o filtro em nomes que contenham Java no titulo e em seguida serao excluidos. Para manter uma versao especifica do Java preencha a variavel e coloque em and not version 'variavel'

gwmi Win32_Product -filter "name like 'Java%' 
AND not version = '$Java1_4' 
AND not version = '$Java1_5' 
AND not version = '$Java6_1' 
AND not version = '$Java6_3' 
AND not version = '$Java6_4' 
AND not version = '$Java7' 
AND not version = '$Java7_0' 
AND not version = '$Java7_1' 
AND not version = '$java7_2' 
AND not version = '$Java7_5' 
AND not version = '$Java7_6' 
AND not version = '$Java7_7' 
AND not version = '$Java7_9'
AND not version = '$Java8' " | % { $_.Uninstall() }