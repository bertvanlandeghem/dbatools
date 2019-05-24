$CommandName = $MyInvocation.MyCommand.Name.Replace(".Tests.ps1", "")
Write-Host -Object "Running $PSCommandPath" -ForegroundColor Cyan
. "$PSScriptRoot\constants.ps1"

Describe "$CommandName Unit Tests" -Tag 'UnitTests' {
    Context "Validate parameters" {
        [object[]]$params = (Get-Command $CommandName).Parameters.Keys | Where-Object {$_ -notin ('whatif', 'confirm')}
        [object[]]$knownParameters = 'Source', 'SourceSqlCredential', 'Destination', 'DestinationSqlCredential', 'Assembly', 'ExcludeAssembly', 'Force', 'EnableException'
        $knownParameters += [System.Management.Automation.PSCmdlet]::CommonParameters
        It "Should only contain our specific parameters" {
            (@(Compare-Object -ReferenceObject ($knownParameters | Where-Object {$_}) -DifferenceObject $params).Count ) | Should Be 0
        }
    }
}

Describe "$commandname Integration Tests" -Tag "IntegrationTests" {
    BeforeAll {
        Get-DbaProcess -SqlInstance $script:instance2, $script:instance3 -Program 'dbatools PowerShell module - dbatools.io' | Stop-DbaProcess -WarningAction SilentlyContinue
        $server = Connect-DbaInstance -SqlInstance $script:instance3
        $server.Query("CREATE DATABASE dbclrassembly")
        $server.Query("EXEC sp_configure 'CLR ENABLED' , '1'")
        $server.Query("RECONFIGURE")
        $server = Connect-DbaInstance -SqlInstance $script:instance2
        $server.Query("CREATE DATABASE dbclrassembly")
        $server.Query("EXEC sp_configure 'CLR ENABLED' , '1'")
        $server.Query("RECONFIGURE")
        $server.Query("ALTER DATABASE dbclrassembly SET TRUSTWORTHY ON")
        $db = Get-Dbadatabase -SqlInstance $script:instance2 -Database dbclrassembly
        $db.Query("CREATE ASSEMBLY [resolveDNS] AUTHORIZATION [dbo] FROM 0x4D5A90000300000004000000FFFF0000B800000000000000400000000000000000000000000000000000000000000000000000000000000000000000800000000E1FBA0E00B409CD21B8014CCD21546869732070726F6772616D2063616E6E6F742062652072756E20696E20444F53206D6F64652E0D0D0A2400000000000000504500004C010300457830570000000000000000E00002210B010B000008000000060000000000002E260000002000000040000000000010002000000002000004000000000000000400000000000000008000000002000000000000030040850000100000100000000010000010000000000000100000000000000000000000E02500004B00000000400000B002000000000000000000000000000000000000006000000C000000A82400001C0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000200000080000000000000000000000082000004800000000000000000000002E7465787400000034060000002000000008000000020000000000000000000000000000200000602E72737263000000B00200000040000000040000000A0000000000000000000000000000400000402E72656C6F6300000C0000000060000000020000000E0000000000000000000000000000400000420000000000000000000000000000000010260000000000004800000002000500A42000000404000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001B3001002F000000010000110000026F0500000A280600000A6F0700000A6F0800000A0A06730900000A0BDE0B260002730900000A0BDE0000072A0001100000000001002021000B010000011E02280A00000A2A42534A4201000100000000000C00000076322E302E35303732370000000005006C00000070010000237E0000DC010000A401000023537472696E67730000000080030000080000002355530088030000100000002347554944000000980300006C00000023426C6F620000000000000002000001471502000900000000FA253300160000010000000A0000000200000002000000010000000A0000000400000001000000010000000300000000000A0001000000000006003E0037000A006600510006009D008A000F00B10000000600E000C00006000001C0000A00440129010600590137000E00700165010E007401650100000000010000000000010001000100100019000000050001000100502000000000960070000A0001009C200000000086187D001000020000000100830019007D00140029007D001A0031007D00100039007D00100041006001240049008001280051008D01240009009A01240011007D002E0009007D001000200023001F002E000B0039002E00130042002E001B004B0033000480000000000000000000000000000000001E01000002000000000000000000000001002E00000000000200000000000000000000000100450000000000020000000000000000000000010037000000000000000000003C4D6F64756C653E007265736F6C7665444E532E646C6C0055736572446566696E656446756E6374696F6E73006D73636F726C69620053797374656D004F626A6563740053797374656D2E446174610053797374656D2E446174612E53716C54797065730053716C537472696E67004950746F486F73744E616D65002E63746F72006970616464720053797374656D2E446961676E6F73746963730044656275676761626C6541747472696275746500446562756767696E674D6F6465730053797374656D2E52756E74696D652E436F6D70696C6572536572766963657300436F6D70696C6174696F6E52656C61786174696F6E734174747269627574650052756E74696D65436F6D7061746962696C697479417474726962757465007265736F6C7665444E53004D6963726F736F66742E53716C5365727665722E5365727665720053716C46756E6374696F6E41747472696275746500537472696E67005472696D0053797374656D2E4E657400446E73004950486F7374456E74727900476574486F7374456E747279006765745F486F73744E616D6500546F537472696E6700000003200000000000BBBB2D2F51E12E4791398BFA79459ABA0008B77A5C561934E08905000111090E03200001052001011111042001010804010000000320000E05000112290E042001010E0507020E11090801000701000000000801000800000000001E01000100540216577261704E6F6E457863657074696F6E5468726F7773010000000000004578305700000000020000001C010000C4240000C40600005253445357549849C5462E43AD588F97CA53634201000000633A5C74656D705C4461746162617365315C4461746162617365315C6F626A5C44656275675C7265736F6C7665444E532E706462000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000826000000000000000000001E260000002000000000000000000000000000000000000000000000102600000000000000005F436F72446C6C4D61696E006D73636F7265652E646C6C0000000000FF25002000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100100000001800008000000000000000000000000000000100010000003000008000000000000000000000000000000100000000004800000058400000540200000000000000000000540234000000560053005F00560045005200530049004F004E005F0049004E0046004F0000000000BD04EFFE00000100000000000000000000000000000000003F000000000000000400000002000000000000000000000000000000440000000100560061007200460069006C00650049006E0066006F00000000002400040000005400720061006E0073006C006100740069006F006E00000000000000B004B4010000010053007400720069006E006700460069006C00650049006E0066006F0000009001000001003000300030003000300034006200300000002C0002000100460069006C0065004400650073006300720069007000740069006F006E000000000020000000300008000100460069006C006500560065007200730069006F006E000000000030002E0030002E0030002E003000000040000F00010049006E007400650072006E0061006C004E0061006D00650000007200650073006F006C007600650044004E0053002E0064006C006C00000000002800020001004C006500670061006C0043006F00700079007200690067006800740000002000000048000F0001004F0072006900670069006E0061006C00460069006C0065006E0061006D00650000007200650073006F006C007600650044004E0053002E0064006C006C0000000000340008000100500072006F006400750063007400560065007200730069006F006E00000030002E0030002E0030002E003000000038000800010041007300730065006D0062006C0079002000560065007200730069006F006E00000030002E0030002E0030002E003000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002000000C000000303600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000")
    }
    AfterAll {
        Get-Dbadatabase -SqlInstance $script:instance2, $script:instance3 -Database dbclrassembly | Remove-DbaDatabase -Confirm:$false
    }

    It "copies the sample database assembly" {
        $results = Copy-DbaDbAssembly -Source $script:instance2 -Destination $script:instance3 -Assembly resolveDNS
        $results.Name -eq "60000:'us_english'", "60000:'Français'"
        $results.Status -eq 'Successful', 'Successful'
    }

    It "doesn't overwrite existing custom errors" {
        $results = Copy-DbaCustomError -Source $script:instance2 -Destination $script:instance3 -CustomError 60000
        $results.Name -eq "60000:'us_english'", "60000:'Français'"
        $results.Status -eq 'Skipped', 'Skipped'
    }

    It "the newly copied custom error exists" {
        $results = Get-DbaCustomError -SqlInstance $script:instance2
        $results.ID -contains 60000
    }
}