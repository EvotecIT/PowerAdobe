function ConvertTo-JsonLiteral {
    <#
    .SYNOPSIS
    Converts an object to a JSON-formatted string.

    .DESCRIPTION
    The ConvertTo-Json cmdlet converts any object to a string in JavaScript Object Notation (JSON) format. The properties are converted to field names, the field values are converted to property values, and the methods are removed.

    .PARAMETER Object
    Specifies the objects to convert to JSON format. Enter a variable that contains the objects, or type a command or expression that gets the objects. You can also pipe an object to ConvertTo-JsonLiteral

    .PARAMETER Depth
    Specifies how many levels of contained objects are included in the JSON representation. The default value is 0.

    .PARAMETER AsArray
    Outputs the object in array brackets, even if the input is a single object.

    .PARAMETER DateTimeFormat
    Changes DateTime string format. Default "yyyy-MM-dd HH:mm:ss"

    .PARAMETER NumberAsString
    Provides an alternative serialization option that converts all numbers to their string representation.

    .PARAMETER BoolAsString
    Provides an alternative serialization option that converts all bool to their string representation.

    .PARAMETER PropertyName
    Uses PropertyNames provided by user (only works with Force)

    .PARAMETER NewLineFormat
    Provides a way to configure how new lines are converted for property names

    .PARAMETER NewLineFormatProperty
    Provides a way to configure how new lines are converted for values

    .PARAMETER PropertyName
    Allows passing property names to be used for custom objects (hashtables and alike are unaffected)

    .PARAMETER ArrayJoin
    Forces any array to be a string regardless of depth level

    .PARAMETER ArrayJoinString
    Uses defined string or char for array join. By default it uses comma with a space when used.

    .PARAMETER Force
    Forces using property names from first object or given thru PropertyName parameter

    .EXAMPLE
    Get-Process | Select-Object -First 2 | ConvertTo-JsonLiteral

    .EXAMPLE
    Get-Process | Select-Object -First 2 | ConvertTo-JsonLiteral -Depth 3

    .EXAMPLE
    Get-Process | Select-Object -First 2 | ConvertTo-JsonLiteral -NewLineFormat $NewLineFormat = @{
        NewLineCarriage = '\r\n'
        NewLine         = "\n"
        Carriage        = "\r"
    } -NumberAsString -BoolAsString

    .EXAMPLE
    Get-Process | Select-Object -First 2 | ConvertTo-JsonLiteral -NumberAsString -BoolAsString -DateTimeFormat "yyyy-MM-dd HH:mm:ss"

    .EXAMPLE
    # Keep in mind this advanced replace will break ConvertFrom-Json, but it's sometimes useful for projects like PSWriteHTML
    Get-Process | Select-Object -First 2 | ConvertTo-JsonLiteral -NewLineFormat $NewLineFormat = @{
        NewLineCarriage = '\r\n'
        NewLine         = "\n"
        Carriage        = "\r"
    } -NumberAsString -BoolAsString -AdvancedReplace @{ '.' = '\.'; '$' = '\$' }

    .NOTES
    General notes
    #>
    [cmdletBinding()]
    param(
        [alias('InputObject')][Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName, Position = 0, Mandatory)][Array] $Object,
        [int] $Depth,
        [switch] $AsArray,
        [string] $DateTimeFormat = "yyyy-MM-dd HH:mm:ss",
        [switch] $NumberAsString,
        [switch] $BoolAsString,
        [System.Collections.IDictionary] $NewLineFormat = @{
            NewLineCarriage = if ([System.Environment]::NewLine -eq "`n") {
                '\n'
            } else {
                '\r\n'
            }
            NewLine         = "\n"
            Carriage        = "\r"
        },
        [System.Collections.IDictionary] $NewLineFormatProperty = @{
            NewLineCarriage = if ([System.Environment]::NewLine -eq "`n") {
                '\n'
            } else {
                '\r\n'
            }
            NewLine         = "\n"
            Carriage        = "\r"
        },
        [System.Collections.IDictionary] $AdvancedReplace,
        [string] $ArrayJoinString,
        [switch] $ArrayJoin,
        [string[]]$PropertyName,
        [switch] $Force
    )
    begin {
        $TextBuilder = [System.Text.StringBuilder]::new()
        $CountObjects = 0
        filter IsNumeric() {
            return $_ -is [byte] -or $_ -is [int16] -or $_ -is [int32] -or $_ -is [int64]  `
                -or $_ -is [sbyte] -or $_ -is [uint16] -or $_ -is [uint32] -or $_ -is [uint64] `
                -or $_ -is [float] -or $_ -is [double] -or $_ -is [decimal]
        }
        filter IsOfType() {
            return $_ -is [bool] -or $_ -is [char] -or $_ -is [datetime] -or $_ -is [string] `
                -or $_ -is [timespan] -or $_ -is [URI] `
                -or $_ -is [byte] -or $_ -is [int16] -or $_ -is [int32] -or $_ -is [int64] `
                -or $_ -is [sbyte] -or $_ -is [uint16] -or $_ -is [uint32] -or $_ -is [uint64] `
                -or $_ -is [float] -or $_ -is [double] -or $_ -is [decimal]
        }
        [int] $MaxDepth = $Depth
        [int] $InitialDepth = 0
    }
    process {
        for ($a = 0; $a -lt $Object.Count; $a++) {
            $CountObjects++
            if ($CountObjects -gt 1) {
                $null = $TextBuilder.Append(',')
            }
            if ($Object[$a] -is [System.Collections.IDictionary]) {
                # Push to TEXT the same as [PSCustomObject]
                $null = $TextBuilder.AppendLine("{")
                for ($i = 0; $i -lt ($Object[$a].Keys).Count; $i++) {
                    $Property = ([string[]]$Object[$a].Keys)[$i] #.Replace('\', "\\").Replace('"', '\"')
                    $DisplayProperty = $Property.Replace('\', "\\").Replace('"', '\"').Replace([System.Environment]::NewLine, $NewLineFormatProperty.NewLineCarriage).Replace("`n", $NewLineFormatProperty.NewLine).Replace("`r", $NewLineFormatProperty.Carriage)
                    $null = $TextBuilder.Append("`"$DisplayProperty`":")
                    $Value = ConvertTo-StringByType -Value $Object[$a][$Property] -DateTimeFormat $DateTimeFormat -NumberAsString:$NumberAsString -BoolAsString:$BoolAsString -Depth $InitialDepth -MaxDepth $MaxDepth -TextBuilder $TextBuilder -NewLineFormat $NewLineFormat -NewLineFormatProperty $NewLineFormatProperty -Force:$Force -ArrayJoin:$ArrayJoin -ArrayJoinString $ArrayJoinString -AdvancedReplace $AdvancedReplace
                    $null = $TextBuilder.Append("$Value")
                    if ($i -ne ($Object[$a].Keys).Count - 1) {
                        $null = $TextBuilder.AppendLine(',')
                    }
                }
                $null = $TextBuilder.Append("}")
            } elseif ($Object[$a] | IsOfType) {
                $Value = ConvertTo-StringByType -Value $Object[$a] -DateTimeFormat $DateTimeFormat -NumberAsString:$NumberAsString -BoolAsString:$BoolAsString -Depth $InitialDepth -MaxDepth $MaxDepth -TextBuilder $TextBuilder -NewLineFormat $NewLineFormat -NewLineFormatProperty $NewLineFormatProperty -Force:$Force -ArrayJoin:$ArrayJoin -ArrayJoinString $ArrayJoinString -AdvancedReplace $AdvancedReplace
                $null = $TextBuilder.Append($Value)
            } else {
                $null = $TextBuilder.AppendLine("{")
                if ($Force -and -not $PropertyName) {
                    $PropertyName = $Object[0].PSObject.Properties.Name
                } elseif ($Force -and $PropertyName) {
                } else {
                    $PropertyName = $Object[$a].PSObject.Properties.Name
                }
                $PropertyCount = 0
                foreach ($Property in $PropertyName) {
                    $PropertyCount++
                    $DisplayProperty = $Property.Replace('\', "\\").Replace('"', '\"').Replace([System.Environment]::NewLine, $NewLineFormatProperty.NewLineCarriage).Replace("`n", $NewLineFormatProperty.NewLine).Replace("`r", $NewLineFormatProperty.Carriage)
                    $null = $TextBuilder.Append("`"$DisplayProperty`":")
                    $Value = ConvertTo-StringByType -Value $Object[$a].$Property -DateTimeFormat $DateTimeFormat -NumberAsString:$NumberAsString -BoolAsString:$BoolAsString -Depth $InitialDepth -MaxDepth $MaxDepth -TextBuilder $TextBuilder -NewLineFormat $NewLineFormat -NewLineFormatProperty $NewLineFormatProperty -Force:$Force -ArrayJoin:$ArrayJoin -ArrayJoinString $ArrayJoinString -AdvancedReplace $AdvancedReplace
                    # Push to Text
                    $null = $TextBuilder.Append("$Value")
                    if ($PropertyCount -ne $PropertyName.Count) {
                        $null = $TextBuilder.AppendLine(',')
                    }
                }
                $null = $TextBuilder.Append("}")
            }
            $InitialDepth = 0
        }
    }
    end {
        if ($CountObjects -gt 1 -or $AsArray) {
            "[$($TextBuilder.ToString())]"
        } else {
            $TextBuilder.ToString()
        }
    }
}
function Join-UriQuery {
    <#
    .SYNOPSIS
    Provides ability to join two Url paths together including advanced querying

    .DESCRIPTION
    Provides ability to join two Url paths together including advanced querying which is useful for RestAPI/GraphApi calls

    .PARAMETER BaseUri
    Primary Url to merge

    .PARAMETER RelativeOrAbsoluteUri
    Additional path to merge with primary url (optional)

    .PARAMETER QueryParameter
    Parameters and their values in form of hashtable

    .PARAMETER EscapeUriString
    If set, will escape the url string

    .EXAMPLE
    Join-UriQuery -BaseUri 'https://evotec.xyz/' -RelativeOrAbsoluteUri '/wp-json/wp/v2/posts' -QueryParameter @{
        page     = 1
        per_page = 20
        search   = 'SearchString'
    }

    .EXAMPLE
    Join-UriQuery -BaseUri 'https://evotec.xyz/wp-json/wp/v2/posts' -QueryParameter @{
        page     = 1
        per_page = 20
        search   = 'SearchString'
    }

    .EXAMPLE
    Join-UriQuery -BaseUri 'https://evotec.xyz' -RelativeOrAbsoluteUri '/wp-json/wp/v2/posts'

    .NOTES
    General notes
    #>
    [alias('Join-UrlQuery')]
    [CmdletBinding()]
    param (
        [parameter(Mandatory)][uri] $BaseUri,
        [parameter(Mandatory = $false)][uri] $RelativeOrAbsoluteUri,
        [Parameter()][System.Collections.IDictionary] $QueryParameter,
        [alias('EscapeUrlString')][switch] $EscapeUriString
    )
    begin {
        Add-Type -AssemblyName System.Web
    }
    process {
        # Join primary url with additional path if needed
        if ($BaseUri -and $RelativeOrAbsoluteUri) {
            $Url = Join-Uri -BaseUri $BaseUri -RelativeOrAbsoluteUri $RelativeOrAbsoluteUri
        } else {
            $Url = $BaseUri
        }

        # Create a http name value collection from an empty string
        if ($QueryParameter) {
            $Collection = [System.Web.HttpUtility]::ParseQueryString([String]::Empty)
            foreach ($key in $QueryParameter.Keys) {
                $Collection.Add($key, $QueryParameter.$key)
            }
        }

        # Build the uri
        $uriRequest = [System.UriBuilder] $Url
        if ($Collection) {
            $uriRequest.Query = $Collection.ToString()
        }
        if (-not $EscapeUriString) {
            $uriRequest.Uri.AbsoluteUri
        } else {
            [System.Uri]::EscapeUriString($uriRequest.Uri.AbsoluteUri)
        }
    }
}
function Remove-EmptyValue {
    <#
    .SYNOPSIS
    Removes empty values from a hashtable recursively.

    .DESCRIPTION
    This function removes empty values from a given hashtable. It can be used to clean up a hashtable by removing keys with null, empty string, empty array, or empty dictionary values. The function supports recursive removal of empty values.

    .PARAMETER Hashtable
    The hashtable from which empty values will be removed.

    .PARAMETER ExcludeParameter
    An array of keys to exclude from the removal process.

    .PARAMETER Recursive
    Indicates whether to recursively remove empty values from nested hashtables.

    .PARAMETER Rerun
    Specifies the number of times to rerun the removal process recursively.

    .PARAMETER DoNotRemoveNull
    If specified, null values will not be removed.

    .PARAMETER DoNotRemoveEmpty
    If specified, empty string values will not be removed.

    .PARAMETER DoNotRemoveEmptyArray
    If specified, empty array values will not be removed.

    .PARAMETER DoNotRemoveEmptyDictionary
    If specified, empty dictionary values will not be removed.

    .EXAMPLE
    $hashtable = @{
        'Key1' = '';
        'Key2' = $null;
        'Key3' = @();
        'Key4' = @{}
    }
    Remove-EmptyValue -Hashtable $hashtable -Recursive

    Description
    -----------
    This example removes empty values from the $hashtable recursively.

    .EXAMPLE
    $SplatDictionary = [ordered] @{
        Test  = $NotExistingParameter
        Test1 = 'Existing Entry'
        Test2 = $null
        Test3 = ''
        Test5 = 0
        Test6 = 6
        Test7 = @{}
    }

    Remove-EmptyValue -Splat $SplatDictionary -Recursive -ExcludeParameter 'Test7'

    $SplatDictionary

    #>
    [alias('Remove-EmptyValues')]
    [CmdletBinding()]
    param(
        [alias('Splat', 'IDictionary')][Parameter(Mandatory)][System.Collections.IDictionary] $Hashtable,
        [string[]] $ExcludeParameter,
        [switch] $Recursive,
        [int] $Rerun,
        [switch] $DoNotRemoveNull,
        [switch] $DoNotRemoveEmpty,
        [switch] $DoNotRemoveEmptyArray,
        [switch] $DoNotRemoveEmptyDictionary
    )
    foreach ($Key in [string[]] $Hashtable.Keys) {
        if ($Key -notin $ExcludeParameter) {
            if ($Recursive) {
                if ($Hashtable[$Key] -is [System.Collections.IDictionary]) {
                    if ($Hashtable[$Key].Count -eq 0) {
                        if (-not $DoNotRemoveEmptyDictionary) {
                            $Hashtable.Remove($Key)
                        }
                    } else {
                        Remove-EmptyValue -Hashtable $Hashtable[$Key] -Recursive:$Recursive -ExcludeParameter $ExcludeParameter -DoNotRemoveNull:$DoNotRemoveNull -DoNotRemoveEmpty:$DoNotRemoveEmpty -DoNotRemoveEmptyArray:$DoNotRemoveEmptyArray -DoNotRemoveEmptyDictionary:$DoNotRemoveEmptyDictionary
                    }
                } else {
                    if (-not $DoNotRemoveNull -and $null -eq $Hashtable[$Key]) {
                        $Hashtable.Remove($Key)
                    } elseif (-not $DoNotRemoveEmpty -and $Hashtable[$Key] -is [string] -and $Hashtable[$Key] -eq '') {
                        $Hashtable.Remove($Key)
                    } elseif (-not $DoNotRemoveEmptyArray -and $Hashtable[$Key] -is [System.Collections.IList] -and $Hashtable[$Key].Count -eq 0) {
                        $Hashtable.Remove($Key)
                    }
                }
            } else {
                if (-not $DoNotRemoveNull -and $null -eq $Hashtable[$Key]) {
                    $Hashtable.Remove($Key)
                } elseif (-not $DoNotRemoveEmpty -and $Hashtable[$Key] -is [string] -and $Hashtable[$Key] -eq '') {
                    $Hashtable.Remove($Key)
                } elseif (-not $DoNotRemoveEmptyArray -and $Hashtable[$Key] -is [System.Collections.IList] -and $Hashtable[$Key].Count -eq 0) {
                    $Hashtable.Remove($Key)
                }
            }
        }
    }
    if ($Rerun) {
        for ($i = 0; $i -lt $Rerun; $i++) {
            Remove-EmptyValue -Hashtable $Hashtable -Recursive:$Recursive -ExcludeParameter $ExcludeParameter -DoNotRemoveNull:$DoNotRemoveNull -DoNotRemoveEmpty:$DoNotRemoveEmpty -DoNotRemoveEmptyArray:$DoNotRemoveEmptyArray -DoNotRemoveEmptyDictionary:$DoNotRemoveEmptyDictionary
        }
    }
}
function ConvertTo-StringByType {
    <#
    .SYNOPSIS
    Private function to use within ConvertTo-JsonLiteral

    .DESCRIPTION
    Private function to use within ConvertTo-JsonLiteral

    .PARAMETER Value
    Value to convert to JsonValue

     .PARAMETER Depth
    Specifies how many levels of contained objects are included in the JSON representation. The default value is 0.

    .PARAMETER AsArray
    Outputs the object in array brackets, even if the input is a single object.

    .PARAMETER DateTimeFormat
    Changes DateTime string format. Default "yyyy-MM-dd HH:mm:ss"

    .PARAMETER NumberAsString
    Provides an alternative serialization option that converts all numbers to their string representation.

    .PARAMETER BoolAsString
    Provides an alternative serialization option that converts all bool to their string representation.

    .PARAMETER PropertyName
    Uses PropertyNames provided by user (only works with Force)

    .PARAMETER ArrayJoin
    Forces any array to be a string regardless of depth level

    .PARAMETER ArrayJoinString
    Uses defined string or char for array join. By default it uses comma with a space when used.

    .PARAMETER Force
    Forces using property names from first object or given thru PropertyName parameter

    .EXAMPLE
    $Value = ConvertTo-StringByType -Value $($Object[$a][$i]) -DateTimeFormat $DateTimeFormat

    .NOTES
    General notes
    #>
    [cmdletBinding()]
    param(
        [Object] $Value,
        [int] $Depth,
        [int] $MaxDepth,
        [string] $DateTimeFormat,
        [switch] $NumberAsString,
        [switch] $BoolAsString,
        [System.Collections.IDictionary] $NewLineFormat = @{
            NewLineCarriage = '\r\n'
            NewLine         = "\n"
            Carriage        = "\r"
        },
        [System.Collections.IDictionary] $NewLineFormatProperty = @{
            NewLineCarriage = '\r\n'
            NewLine         = "\n"
            Carriage        = "\r"
        },
        [System.Collections.IDictionary] $AdvancedReplace,
        [System.Text.StringBuilder] $TextBuilder,
        [string[]] $PropertyName,
        [switch] $ArrayJoin,
        [string] $ArrayJoinString,
        [switch] $Force
    )
    process {
        if ($null -eq $Value) {
            "`"`""
        } elseif ($Value -is [string]) {
            $Value = $Value.Replace('\', "\\").Replace('"', '\"').Replace([System.Environment]::NewLine, $NewLineFormat.NewLineCarriage).Replace("`n", $NewLineFormat.NewLine).Replace("`r", $NewLineFormat.Carriage)
            #$Value = $Value.Replace('.', '\.').Replace('$', '\$')
            foreach ($Key in $AdvancedReplace.Keys) {
                $Value = $Value.Replace($Key, $AdvancedReplace[$Key])
            }
            "`"$Value`""
        } elseif ($Value -is [DateTime]) {
            "`"$($($Value).ToString($DateTimeFormat))`""
        } elseif ($Value -is [bool]) {
            if ($BoolAsString) {
                "`"$($Value)`""
            } else {
                $Value.ToString().ToLower()
            }
        } elseif ($Value -is [System.Collections.IDictionary]) {
            if ($MaxDepth -eq 0 -or $Depth -eq $MaxDepth) {
                "`"$($Value)`""
            } else {
                $Depth++
                $null = $TextBuilder.AppendLine("{")
                for ($i = 0; $i -lt ($Value.Keys).Count; $i++) {
                    $Property = ([string[]]$Value.Keys)[$i]
                    $DisplayProperty = $Property.Replace('\', "\\").Replace('"', '\"').Replace([System.Environment]::NewLine, $NewLineFormatProperty.NewLineCarriage).Replace("`n", $NewLineFormatProperty.NewLine).Replace("`r", $NewLineFormatProperty.Carriage)
                    $null = $TextBuilder.Append("`"$DisplayProperty`":")
                    $OutputValue = ConvertTo-StringByType -Value $Value[$Property] -DateTimeFormat $DateTimeFormat -NumberAsString:$NumberAsString -BoolAsString:$BoolAsString -Depth $Depth -MaxDepth $MaxDepth -TextBuilder $TextBuilder -NewLineFormat $NewLineFormat -NewLineFormatProperty $NewLineFormatProperty -AdvancedReplace $AdvancedReplace -Force:$Force -ArrayJoinString $ArrayJoinString -ArrayJoin:$ArrayJoin.IsPresent
                    $null = $TextBuilder.Append("$OutputValue")
                    if ($i -ne ($Value.Keys).Count - 1) {
                        $null = $TextBuilder.AppendLine(',')
                    }
                }
                $null = $TextBuilder.Append("}")
            }
        } elseif ($Value -is [System.Collections.IList] -or $Value -is [System.Collections.ReadOnlyCollectionBase]) {
            if ($ArrayJoin) {
                $Value = ConvertTo-InvariantJoinedString -Value $Value -Separator $ArrayJoinString
                $Value = "$Value".Replace('\', "\\").Replace('"', '\"').Replace([System.Environment]::NewLine, $NewLineFormatProperty.NewLineCarriage).Replace("`n", $NewLineFormatProperty.NewLine).Replace("`r", $NewLineFormatProperty.Carriage)
                "`"$Value`""
            } else {
                if ($MaxDepth -eq 0 -or $Depth -eq $MaxDepth) {
                    $Value = "$Value".Replace('\', "\\").Replace('"', '\"').Replace([System.Environment]::NewLine, $NewLineFormatProperty.NewLineCarriage).Replace("`n", $NewLineFormatProperty.NewLine).Replace("`r", $NewLineFormatProperty.Carriage)
                    "`"$Value`""
                } else {
                    $CountInternalObjects = 0
                    $null = $TextBuilder.Append("[")
                    foreach ($V in $Value) {
                        $CountInternalObjects++
                        if ($CountInternalObjects -gt 1) {
                            $null = $TextBuilder.Append(',')
                        }
                        if ($Force -and -not $PropertyName) {
                            $PropertyName = $V.PSObject.Properties.Name
                        } elseif ($Force -and $PropertyName) {
                        } else {
                            $PropertyName = $V.PSObject.Properties.Name
                        }
                        $OutputValue = ConvertTo-StringByType -Value $V -DateTimeFormat $DateTimeFormat -NumberAsString:$NumberAsString -BoolAsString:$BoolAsString -Depth $Depth -MaxDepth $MaxDepth -TextBuilder $TextBuilder -NewLineFormat $NewLineFormat -NewLineFormatProperty $NewLineFormatProperty -AdvancedReplace $AdvancedReplace -Force:$Force -PropertyName $PropertyName -ArrayJoinString $ArrayJoinString -ArrayJoin:$ArrayJoin.IsPresent
                        $null = $TextBuilder.Append($OutputValue)
                    }
                    $null = $TextBuilder.Append("]")
                }
            }
        } elseif ($Value -is [System.Enum] -or $Value.PSTypeNames -contains 'Deserialized.System.Enum') {
            "`"$($($Value).ToString())`""
        } elseif (($Value | IsNumeric) -eq $true) {
            $Value = [System.Convert]::ToString($Value, [System.Globalization.CultureInfo]::InvariantCulture)
            if ($NumberAsString) {
                "`"$Value`""
            } else {
                $Value
            }
        } elseif ($Value -is [PSObject]) {
            if ($MaxDepth -eq 0 -or $Depth -eq $MaxDepth) {
                "`"$($Value)`""
            } else {
                $Depth++
                $CountInternalObjects = 0
                $null = $TextBuilder.AppendLine("{")
                if ($Force -and -not $PropertyName) {
                    $PropertyName = $Value.PSObject.Properties.Name
                } elseif ($Force -and $PropertyName) {
                } else {
                    $PropertyName = $Value.PSObject.Properties.Name
                }
                foreach ($Property in $PropertyName) {
                    $CountInternalObjects++
                    if ($CountInternalObjects -gt 1) {
                        $null = $TextBuilder.AppendLine(',')
                    }
                    $DisplayProperty = $Property.Replace('\', "\\").Replace('"', '\"').Replace([System.Environment]::NewLine, $NewLineFormatProperty.NewLineCarriage).Replace("`n", $NewLineFormatProperty.NewLine).Replace("`r", $NewLineFormatProperty.Carriage)
                    $null = $TextBuilder.Append("`"$DisplayProperty`":")
                    $OutputValue = ConvertTo-StringByType -Value $Value.$Property -DateTimeFormat $DateTimeFormat -NumberAsString:$NumberAsString -BoolAsString:$BoolAsString -Depth $Depth -MaxDepth $MaxDepth -TextBuilder $TextBuilder -NewLineFormat $NewLineFormat -NewLineFormatProperty $NewLineFormatProperty -AdvancedReplace $AdvancedReplace -Force:$Force -ArrayJoinString $ArrayJoinString -ArrayJoin:$ArrayJoin.IsPresent
                    $null = $TextBuilder.Append("$OutputValue")
                }
                $null = $TextBuilder.Append("}")
            }
        } else {
            $Value = $Value.ToString().Replace('\', "\\").Replace('"', '\"').Replace([System.Environment]::NewLine, $NewLineFormatProperty.NewLineCarriage).Replace("`n", $NewLineFormatProperty.NewLine).Replace("`r", $NewLineFormatProperty.Carriage)
            "`"$Value`""
        }
    }
}
function Join-Uri {
    <#
    .SYNOPSIS
    Provides ability to join two Url paths together

    .DESCRIPTION
    Provides ability to join two Url paths together

    .PARAMETER BaseUri
    Primary Url to merge

    .PARAMETER RelativeOrAbsoluteUri
    Additional path to merge with primary url

    .EXAMPLE
    Join-Uri 'https://evotec.xyz/' '/wp-json/wp/v2/posts'

    .EXAMPLE
    Join-Uri 'https://evotec.xyz/' 'wp-json/wp/v2/posts'

    .EXAMPLE
    Join-Uri -BaseUri 'https://evotec.xyz/' -RelativeOrAbsoluteUri '/wp-json/wp/v2/posts'

    .EXAMPLE
    Join-Uri -BaseUri 'https://evotec.xyz/test/' -RelativeOrAbsoluteUri '/wp-json/wp/v2/posts'

    .NOTES
    General notes
    #>
    [alias('Join-Url')]
    [cmdletBinding()]
    param(
        [parameter(Mandatory)][uri] $BaseUri,
        [parameter(Mandatory)][uri] $RelativeOrAbsoluteUri
    )

    return ($BaseUri.OriginalString.TrimEnd('/') + "/" + $RelativeOrAbsoluteUri.OriginalString.TrimStart('/'))
    #return [Uri]::new([Uri]::new($BaseUri), $RelativeOrAbsoluteUri).ToString()
    #return [Uri]::new($BaseUri.OriginalString, $RelativeOrAbsoluteUri).ToString()
}
function ConvertTo-InvariantJoinedString {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [System.Collections.IEnumerable] $Value,

        [AllowNull()]
        [string] $Separator
    )

    $ConvertedValues = [System.Collections.Generic.List[string]]::new()
    foreach ($Item in $Value) {
        if ($null -eq $Item) {
            $ConvertedValues.Add([string]::Empty)
        } elseif (
            $Item -is [byte] -or $Item -is [int16] -or $Item -is [int32] -or $Item -is [int64] -or
            $Item -is [sbyte] -or $Item -is [uint16] -or $Item -is [uint32] -or $Item -is [uint64] -or
            $Item -is [float] -or $Item -is [double] -or $Item -is [decimal]
        ) {
            $ConvertedValues.Add([System.Convert]::ToString($Item, [System.Globalization.CultureInfo]::InvariantCulture))
        } else {
            $ConvertedValues.Add([string] $Item)
        }
    }

    $ConvertedValues -join $Separator
}

# PowerForge merged source begin cb996f3cbd50496d0c97f4e8e76046b630c690fce2bf0232b10edb252c788074
function Invoke-AdobeQuery {
    <#
    .SYNOPSIS
    Executes a query against the Adobe User Management API.

    .DESCRIPTION
    The Invoke-AdobeQuery function sends HTTP requests to the Adobe User Management API. It handles GET and other HTTP methods, manages pagination, and processes responses.

    .PARAMETER BaseUri
    The base URI for the Adobe User Management API. Defaults to 'https://usermanagement.adobe.io/v2/usermanagement'.

    .PARAMETER Url
    The endpoint URL for the specific API call.

    .PARAMETER Method
    The HTTP method to use for the request (e.g., GET, POST).

    .PARAMETER Data
    The data to include in the body of the request, applicable for methods like POST.

    .PARAMETER QueryParameter
    Additional query parameters to include in the request URI.

    .EXAMPLE
    Invoke-AdobeQuery -Url "users" -Method "GET"

    .EXAMPLE
    Invoke-AdobeQuery -Url "groups" -Method "POST" -Data $groupData
    #>
    [CmdletBinding()]
    param(
        [string] $BaseUri = 'https://usermanagement.adobe.io/v2/usermanagement',
        [Parameter(Mandatory)][string] $Url,
        [Parameter(Mandatory)][string] $Method,
        [Parameter()][System.Collections.IDictionary[]] $Data,
        [Parameter()][System.Collections.IDictionary] $QueryParameter
    )
    $Organization = $($($Script:AdobeTokenInformation).Organization)
    if ($Method -eq 'GET') {
        $Page = 0
        $Paged = $Url.Contains('{page}')
        $Strict = $ErrorActionPreference -eq [System.Management.Automation.ActionPreference]::Stop
        do {
            $UsedUrl = $Url.Replace('{orgId}', $Organization).Replace('{page}', [string] $Page)
            $UriToUse = Join-UriQuery -BaseUri $BaseUri -RelativeOrAbsoluteUri $UsedUrl -QueryParameter $QueryParameter
            Write-Verbose -Message "Invoke-AdobeQuery - Url: $UriToUse / Method: $Method / Page: $Page"
            try {
                $Response = Invoke-WebRequest -Method Get -Uri $UriToUse -Headers $Script:AdobeTokenInformation.Headers -ErrorAction Stop -Verbose:$false
                if (-not $Response -or [string]::IsNullOrWhiteSpace($Response.Content)) {
                    throw 'Adobe returned an empty response.'
                }
                $Output = $Response.Content | ConvertFrom-Json -ErrorAction Stop
                if ($Output -isnot [System.Management.Automation.PSCustomObject]) {
                    throw 'Adobe returned an invalid response object.'
                }
                if ($Output.result -and $Output.result -ne 'success') {
                    throw 'Adobe reported an unsuccessful result.'
                }
                if ($Paged -and ($Output.lastPage -isnot [bool] -or (-not $Output.PSObject.Properties['users'] -and -not $Output.PSObject.Properties['groups']))) {
                    throw 'Adobe returned an invalid paged response.'
                }
                if ($Paged -and (($Output.PSObject.Properties['users'] -and $Output.users -isnot [array]) -or ($Output.PSObject.Properties['groups'] -and $Output.groups -isnot [array]))) {
                    throw 'Adobe returned an invalid page collection.'
                }
            } catch {
                $Message = "Invoke-AdobeQuery - GET failed for organization '$Organization' at page $Page. A complete result could not be retrieved. Check authentication, service availability, and the response format."
                if ($Strict) {
                    throw $Message
                }
                Write-Warning -Message $Message
                return
            }
            if ($null -ne $Output.PSObject.Properties['users']) {
                $Output.users
            } elseif ($null -ne $Output.PSObject.Properties['groups']) {
                $Output.groups
            } elseif ($null -ne $Output.PSObject.Properties['user']) {
                $Output.user
            } else {
                $Output
            }
            $Page++
        } while ($Paged -and -not $Output.lastPage)
    } else {
        $UriToUse = Join-UriQuery -BaseUri $BaseUri -RelativeOrAbsoluteUri "$Url/$Organization" -QueryParameter $QueryParameter

        Write-Verbose -Message "Invoke-AdobeQuery - Url: $UriToUse / Method: $Method"
        try {
            if ($PSVersionTable.PSVersion.Major -lt 6) {
                $DataJSON = @($Data) | ConvertTo-JsonLiteral -Depth 5 -AsArray
            } else {
                $DataJSON = @($Data) | ConvertTo-Json -Depth 5 -AsArray
            }
            $Response = Invoke-WebRequest -Method $Method -Uri $UriToUse -Headers $Script:AdobeTokenInformation.Headers -ErrorAction Stop -Verbose:$false -Body $DataJSON
        } catch {
            if ($_.Exception.Response.StatusCode -eq 'TooManyRequests') {
                $TimeToRetry = $_.Exception.Response.Headers.RetryAfter
                Write-Warning -Message "Invoke-AdobeQuery - Too many requests. Retry after $TimeToRetry seconds"
            } else {
                $ErrorDetails = $_.ErrorDetails
                if ($_.ErrorDetails.Message) {
                    try {
                        $Message = $_.Exception.Message
                        $ErrorCode = $_.ErrorDetails.Message | ConvertFrom-Json -ErrorAction Stop
                        if ($ErrorCode) {
                            Write-Warning -Message "Invoke-AdobeQuery - Unable to connect to organization '$Organization'. Error code $($ErrorCode.error_Code) / $($ErrorCode.message)"
                        } else {
                            Write-Warning -Message "Invoke-AdobeQuery - Unable to connect to organization '$Organization'. Error $Message"
                        }
                    } catch {
                        Write-Warning -Message "Invoke-AdobeQuery - Unable to connect to organization '$Organization'. Error $($_.Exception.Message), ErrorDetails: $($ErrorDetails.Message)"
                    }
                } else {
                    Write-Warning -Message "Invoke-AdobeQuery - Unable to connect to organization '$Organization'. Error $($_.Exception.Message), ErrorDetails: $($ErrorDetails.Message)"
                }
            }
        }
        if ($Response -and $Response.Content) {
            $Output = $Response.Content | ConvertFrom-Json -ErrorAction SilentlyContinue
            $Output
        } elseif ($Response) {
            $Response
        }
    }
}
# PowerForge merged source end cb996f3cbd50496d0c97f4e8e76046b630c690fce2bf0232b10edb252c788074

# PowerForge merged source begin cb996f3cbd50496d0c97f4e8e76046b630c690fce2bf0232b10edb252c788074
function Add-AdobeGroupMember {
    <#
    .SYNOPSIS
    Adds a member to an Adobe group.

    .DESCRIPTION
    The Add-AdobeGroupMember cmdlet adds a specified user to one or more Adobe groups. It supports bulk processing for adding multiple groups at once.

    .PARAMETER GroupName
    The name(s) of the Adobe group(s) to which the user will be added.

    .PARAMETER Email
    The email address of the user to be added to the group(s).

    .PARAMETER BulkProcessing
    Enables bulk processing mode for adding multiple groups simultaneously.

    .EXAMPLE
    Add-AdobeGroupMember -GroupName "Admins" -Email "john.doe@example.com"

    .EXAMPLE
    Add-AdobeGroupMember -GroupName "Admins","Developers" -Email "john.doe@example.com" -BulkProcessing
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][string[]] $GroupName,
        [Parameter(Mandatory)][string] $Email,
        [switch] $BulkProcessing
    )
    if (-not $Script:AdobeTokenInformation) {
        Write-Warning -Message 'Add-AdobeGroupMember - You need to connect to Adobe first using Connect-Adobe'
        return
    }
    if ($GroupName.Count -gt 10) {
        Write-Warning -Message 'Add-AdobeGroupMember - Only ten groups can be added at a time'
        return
    }
    $Data = [ordered] @{
        user      = $Email
        requestID = "action_$(Get-Random)"
        do        = @(
            @{
                'add' = @{
                    'group' = @(
                        $GroupName
                    )
                }
            }
        )
    }

    Remove-EmptyValue -Hashtable $Data -Recursive -Rerun 2

    if ($BulkProcessing) {
        return $Data
    }

    $Data | ConvertTo-Json -Depth 5 | Write-Verbose

    $QueryParameter = [ordered] @{
        testOnly = if ($PSCmdlet.ShouldProcess($GroupName, 'Add Adobe Group Member')) {
            $false
        } else {
            $true
        }
    }

    Invoke-AdobeQuery -Url "action" -Method 'POST' -Data $Data -QueryParameter $QueryParameter
}
# PowerForge merged source end cb996f3cbd50496d0c97f4e8e76046b630c690fce2bf0232b10edb252c788074

# PowerForge merged source begin cb996f3cbd50496d0c97f4e8e76046b630c690fce2bf0232b10edb252c788074
function Connect-Adobe {
    <#
    .SYNOPSIS
    Connects to the Adobe API.

    .DESCRIPTION
    The Connect-Adobe cmdlet establishes a connection to the Adobe API using the provided credentials and scopes. It handles token retrieval and caching for subsequent API calls.

    .PARAMETER ClientID
    The Client ID for Adobe API authentication.

    .PARAMETER ClientSecret
    The Client Secret for Adobe API authentication.

    .PARAMETER ClientSecretEncrypted
    The encrypted Client Secret for Adobe API authentication.

    .PARAMETER Scopes
    The scopes for API access.

    .PARAMETER Organization
    The Adobe organization identifier.

    .PARAMETER ExistingToken
    Use an existing token if available.

    .PARAMETER DoNotSuppress
    Suppress suppression of the token information.

    .PARAMETER Force
    Force a new token retrieval even if a valid token exists.

    .EXAMPLE
    Connect-Adobe -ClientID "your_client_id" -ClientSecret "your_client_secret" -Scopes "openid, AdobeID" -Organization "your_org_id"
    #>
    [CmdletBinding()]
    param(
        [parameter(Mandatory)][string] $ClientID,

        [Parameter(Mandatory, ParameterSetName = 'ClearText')]
        [parameter(Mandatory)][string] $ClientSecret,

        [Parameter(Mandatory, ParameterSetName = 'Encrypted')]
        [alias('ApplicationSecretEncrypted', 'ApplicationKeyEncrypted')]
        [string] $ClientSecretEncrypted,

        [parameter(Mandatory)][string] $Scopes,
        [parameter(Mandatory)][string] $Organization,
        [switch] $ExistingToken,
        [switch] $DoNotSuppress,
        [switch] $Force
    )
    # Check for curent token
    $CurrentTime = (Get-Date).AddSeconds(2)

    if ($ClientSecretEncrypted) {
        try {
            $ApplicationKeyTemp = $ClientSecretEncrypted | ConvertTo-SecureString -ErrorAction Stop
        } catch {
            if ($PSBoundParameters.ErrorAction -eq 'Stop') {
                throw
            } else {
                $ErrorMessage = $_.Exception.Message -replace "`n", " " -replace "`r", " "
                Write-Warning -Message "Connect-Adobe - Error: $ErrorMessage"
                return
            }
        }
        $ApplicationKey = [System.Net.NetworkCredential]::new([string]::Empty, $ApplicationKeyTemp).Password
    } else {
        $ApplicationKey = $ClientSecret
    }

    if ($Script:AdobeTokenInformation.Expires -lt $CurrentTime -or $Force) {
        if ($ExistingToken) {
            Write-Verbose -Message "Connect-Adobe - Using existing token within command"
            $Url = $Script:AdobeTokenInformation.Url
            $Headers = $Script:AdobeTokenInformation.Headers
            $Body = $Script:AdobeTokenInformation.Body
        } else {
            $Headers = [ordered] @{
                'Content-Type' = 'application/x-www-form-urlencoded'
            }
            $Body = [ordered] @{
                'client_id'     = $ClientID
                'client_secret' = $ApplicationKey
                'grant_type'    = 'client_credentials'
                'scope'         = $Scopes
            }
            $Url = 'https://ims-na1.adobelogin.com/ims/token/v3'

            $Script:AdobeTokenInformation = [ordered] @{
                Organization = $Organization
                Url          = $Url
                Headers      = $Headers
                Token        = $null
                Expires      = $null
                Body         = $Body
            }
        }

        try {
            $Response = Invoke-RestMethod -Method Post -Uri $Url -Headers $Headers -Body $Body -ErrorAction Stop -Verbose:$false
        } catch {
            Write-Warning -Message "Connect-Adobe - Unable to connect to organization '$Organization' with user '$UserName'. Error $($_.Exception.Message)"
            return
        }

        $Script:AdobeTokenInformation.Token = $Response.access_token
        $Script:AdobeTokenInformation.Expires = [DateTime]::Now + ([TimeSpan]::FromSeconds($Response.expires_in))
        $Script:AdobeTokenInformation.Headers = @{
            #'Content-Type'  = 'application/x-www-form-urlencoded'
            'Authorization' = "Bearer $($Script:AdobeTokenInformation.Token)"
            "X-Api-Key"     = "$ClientID"
            'Content-type'  = 'application/json'
        }
        if ($DoNotSuppress) {
            $Script:AdobeTokenInformation
        }
    } else {
        $WhenExpires = $Script:AdobeTokenInformation.expires - $CurrentTime
        Write-Verbose -Message "Connect-Adobe - Using existing cached token (Expires in: $WhenExpires)"
        if ($DoNotSuppress -and -not $ExistingToken) {
            $Script:AdobeTokenInformation
        }
    }
}
# PowerForge merged source end cb996f3cbd50496d0c97f4e8e76046b630c690fce2bf0232b10edb252c788074

# PowerForge merged source begin cb996f3cbd50496d0c97f4e8e76046b630c690fce2bf0232b10edb252c788074
function Get-AdobeGroup {
    <#
    .SYNOPSIS
    Retrieves Adobe groups.

    .DESCRIPTION
    The Get-AdobeGroup cmdlet lists all user groups within the Adobe system. It requires an active Adobe connection.

    .EXAMPLE
    Get-AdobeGroup
    #>
    [CmdletBinding()]
    param(

    )
    if (-not $Script:AdobeTokenInformation) {
        if ($ErrorActionPreference -eq [System.Management.Automation.ActionPreference]::Stop) {
            throw 'Adobe authorization is not available. Run Connect-Adobe before retrieving data.'
        }
        Write-Warning -Message 'Get-AdobeGroup - You need to connect to Adobe first using Connect-Adobe'
        return
    }

    Invoke-AdobeQuery -Url "groups/{orgId}/{page}" -Method 'GET'
}
# PowerForge merged source end cb996f3cbd50496d0c97f4e8e76046b630c690fce2bf0232b10edb252c788074

# PowerForge merged source begin cb996f3cbd50496d0c97f4e8e76046b630c690fce2bf0232b10edb252c788074
function Get-AdobeGroupMember {
    <#
    .SYNOPSIS
    Retrieves members of a specified Adobe group.

    .DESCRIPTION
    The Get-AdobeGroupMember cmdlet fetches all members belonging to a specific group within the Adobe system. Requires an active Adobe connection.

    .PARAMETER GroupName
    The name of the group to retrieve members for.

    .EXAMPLE
    Get-AdobeGroupMember -GroupName "Admins"
    #>
    [CmdletBinding()]
    param(
        [parameter(Mandatory)][string] $GroupName
    )
    if (-not $Script:AdobeTokenInformation) {
        if ($ErrorActionPreference -eq [System.Management.Automation.ActionPreference]::Stop) {
            throw 'Adobe authorization is not available. Run Connect-Adobe before retrieving data.'
        }
        Write-Warning -Message 'Get-AdobeGroup - You need to connect to Adobe first using Connect-Adobe'
        return
    }

    Invoke-AdobeQuery -Url "users/{orgId}/{page}/$GroupName" -Method 'GET'
}
# PowerForge merged source end cb996f3cbd50496d0c97f4e8e76046b630c690fce2bf0232b10edb252c788074

# PowerForge merged source begin cb996f3cbd50496d0c97f4e8e76046b630c690fce2bf0232b10edb252c788074
function Get-AdobeUser {
    <#
    .SYNOPSIS
    Retrieves Adobe user information.

    .DESCRIPTION
    The Get-AdobeUser cmdlet fetches details of a specific Adobe user or lists all users if no email is provided. Requires an active Adobe connection.

    .PARAMETER Email
    The email address of the user to retrieve information for.

    .EXAMPLE
    Get-AdobeUser -Email "jane.doe@example.com"

    .EXAMPLE
    Get-AdobeUser
    #>
    [CmdletBinding()]
    param(
        [string] $Email
    )
    if (-not $Script:AdobeTokenInformation) {
        if ($ErrorActionPreference -eq [System.Management.Automation.ActionPreference]::Stop) {
            throw 'Adobe authorization is not available. Run Connect-Adobe before retrieving data.'
        }
        Write-Warning -Message 'Get-AdobeUser - You need to connect to Adobe first using Connect-Adobe'
        return
    }

    if ($Email) {
        #Get user information : GET /v2/usermanagement/organizations/{orgId}/users/{userString}
        Invoke-AdobeQuery -Url "organizations/{orgId}/users/$Email" -Method 'GET'
    } else {
        #List all users : GET /v2/usermanagement/users/{orgId}/{page}
        Invoke-AdobeQuery -Url "users/{orgId}/{page}" -Method 'GET'
    }
}
# PowerForge merged source end cb996f3cbd50496d0c97f4e8e76046b630c690fce2bf0232b10edb252c788074

# PowerForge merged source begin cb996f3cbd50496d0c97f4e8e76046b630c690fce2bf0232b10edb252c788074
function Invoke-AdobeBulk {
    <#
    .SYNOPSIS
    Executes bulk operations on Adobe users.

    .DESCRIPTION
    The Invoke-AdobeBulk cmdlet performs multiple Adobe user operations in a single request. It processes actions defined in a script block in batches of 20 to comply with Adobe's API limitations, ensures actions are executed in order, and aggregates the results to provide a single consolidated output at the end.

    .PARAMETER Actions
    A script block containing the bulk actions to execute. Each action should be a PowerShell cmdlet that modifies Adobe user or group information.

    .PARAMETER Suppress
    Suppresses the output of errors. When this switch is used, any errors encountered during the execution of bulk actions will not be displayed.

    .EXAMPLE
    # Execute bulk operations to add and update Adobe users
    Invoke-AdobeBulk {
        Add-AdobeUser -EmailAddress "john.doe@example.com" -Country "US" -FirstName "John" -LastName "Doe" -Type "createFederatedID" -BulkProcessing
        Set-AdobeUser -EmailAddress "john.doe@example.com" -LastName "Doe-Smith" -BulkProcessing
    }

    .EXAMPLE
    # Execute bulk operations and suppress error output
    Invoke-AdobeBulk {
        Add-AdobeUser -EmailAddress "jane.doe@example.com" -Country "UK" -FirstName "Jane" -LastName "Doe" -Type "createEnterpriseID" -BulkProcessing
        Set-AdobeUser -EmailAddress "jane.doe@example.com" -LastName "Doe-Smith" -BulkProcessing
    } -Suppress

    .NOTES
    - Ensure that you have connected to Adobe using `Connect-Adobe` before executing bulk operations.
    - The cmdlet processes actions in the order they are provided and aggregates the results to provide a comprehensive status report at the end of execution.
    - Adobe API limits bulk requests to 20 actions per batch. This cmdlet automatically handles batching to adhere to this limitation.
    - The aggregated output includes counts of completed, not completed, and completed in test mode actions, as well as any errors encountered during execution.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [scriptblock] $Actions,
        [switch] $Suppress
    )
    if (-not $Script:AdobeTokenInformation) {
        Write-Warning -Message 'Invoke-AdobeBulk - You need to connect to Adobe first using Connect-Adobe'
        return
    }

    $AllActions = & $Actions
    [Array] $ActionsToExecute = foreach ($Action in $AllActions) {
        $Action
    }

    # Initialize aggregation variables
    $aggregatedResult = [ordered] @{
        completed           = 0
        notCompleted        = 0
        completedInTestMode = 0
        result              = 'success'
        errors              = @()
    }

    $QueryParameter = [ordered] @{
        testOnly = if ($PSCmdlet.ShouldProcess("Updates", 'Do bulk updates')) {
            $false
        } else {
            $true
        }
    }

    # Process actions in batches of 20
    for ($i = 0; $i -lt $ActionsToExecute.Count; $i += 20) {
        $Batch = $ActionsToExecute[$i..([math]::Min($i + 19, $ActionsToExecute.Count - 1))]

        $Batch | ConvertTo-Json -Depth 5 | Write-Verbose

        $batchOutput = Invoke-AdobeQuery -Url "action" -Method 'POST' -Data $Batch -QueryParameter $QueryParameter
        foreach ($ErrorMessage in $batchOutput.Errors) {
            Write-Warning -Message "Invoke-AdobeBulk - Processing error [user: $($ErrorMessage.User), index: $($ErrorMessage.Index)] - $($ErrorMessage.Message)"
        }

        # Aggregate results
        $aggregatedResult.completed += $batchOutput.completed
        $aggregatedResult.notCompleted += $batchOutput.notCompleted
        $aggregatedResult.completedInTestMode += $batchOutput.completedInTestMode
        if ($batchOutput.errors) {
            $aggregatedResult.errors += $batchOutput.errors
            #$aggregatedResult.failed += $batchOutput.errors.Count
        }

        # Update overall result status
        if ($batchOutput.result -eq 'failure') {
            $aggregatedResult.result = 'failure'
        } elseif ($batchOutput.result -ne 'success' -and $aggregatedResult.result -ne 'failure') {
            $aggregatedResult.result = 'partial'
        }
    }

    # Determine overall result based on aggregated data
    if ($aggregatedResult.failed -eq $ActionsToExecute.Count) {
        $aggregatedResult.result = 'failure'
    } elseif ($aggregatedResult.notCompleted -gt 0) {
        $aggregatedResult.result = 'partial'
    } else {
        $aggregatedResult.result = 'success'
    }

    if (-not $Suppress) {
        # Output the aggregated results
        $aggregatedResult
    }
}
# PowerForge merged source end cb996f3cbd50496d0c97f4e8e76046b630c690fce2bf0232b10edb252c788074

# PowerForge merged source begin cb996f3cbd50496d0c97f4e8e76046b630c690fce2bf0232b10edb252c788074
function New-AdobeGroup {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][string] $Name,
        [Parameter()][string] $Description,
        [ValidateSet('ignoreIfAlreadyExists', 'updateIfAlreadyExists')]
        [string] $Option = 'ignoreIfAlreadyExists',
        [switch] $BulkProcessing
    )

    $OptionList = @{
        ignoreIfAlreadyExists = 'ignoreIfAlreadyExists'
        updateIfAlreadyExists = 'updateIfAlreadyExists'
    }
    $OptionConverted = $OptionList[$Option]

    if (-not $Script:AdobeTokenInformation) {
        Write-Warning -Message 'Get-AdobeUser - You need to connect to Adobe first using Connect-Adobe'
        return
    }

    $Data = [ordered] @{
        usergroup = $Name
        requestID = "action_$(Get-Random)"
        do        = @(
            [ordered] @{
                'createUserGroup' = [ordered] @{
                    name        = $Name
                    description = $Description
                    option      = $OptionConverted
                }
            }
        )
    }

    Remove-EmptyValue -Hashtable $Data -Recursive -Rerun 2

    if ($BulkProcessing) {
        return $Data
    }

    $Data | ConvertTo-Json -Depth 5 | Write-Verbose

    $QueryParameter = [ordered] @{
        testOnly = if ($PSCmdlet.ShouldProcess($Name, 'Create Adobe Group')) {
            $false
        } else {
            $true
        }
    }

    Invoke-AdobeQuery -Url "action" -Method 'POST' -Data $Data -QueryParameter $QueryParameter
}
# PowerForge merged source end cb996f3cbd50496d0c97f4e8e76046b630c690fce2bf0232b10edb252c788074

# PowerForge merged source begin cb996f3cbd50496d0c97f4e8e76046b630c690fce2bf0232b10edb252c788074
function New-AdobeUser {
    <#
    .SYNOPSIS
    Creates a new Adobe user.

    .DESCRIPTION
    The New-AdobeUser cmdlet adds a new user to the Adobe system with specified details. It supports bulk processing and different user types.

    .PARAMETER EmailAddress
    The email address of the new user.

    .PARAMETER Country
    The country of the new user.

    .PARAMETER FirstName
    The first name of the new user.

    .PARAMETER LastName
    The last name of the new user.

    .PARAMETER Option
    Determines how to handle existing users. Options are 'ignoreIfAlreadyExists' or 'updateIfAlreadyExists'.

    .PARAMETER Type
    Specifies the type of Adobe ID to create. Valid values are 'createEnterpriseID', 'addAdobeID', or 'createFederatedID'.

    .PARAMETER BulkProcessing
    Switch to enable bulk processing mode.

    .EXAMPLE
    New-AdobeUser -EmailAddress "jane.doe@example.com" -Country "US" -FirstName "Jane" -LastName "Doe" -Type "createFederatedID"
    #>
    [Alias('Add-AdobeUser')]
    [cmdletbinding(SupportsShouldProcess)]
    param(
        [string] $EmailAddress,
        [string] $Country,
        [string] $FirstName,
        [string] $LastName,

        [ValidateSet('ignoreIfAlreadyExists', 'updateIfAlreadyExists')]
        [string] $Option = 'ignoreIfAlreadyExists',

        [Parameter(Mandatory)]
        [ValidateSet('createEnterpriseID', 'addAdobeID', 'createFederatedID')]
        [string] $Type,
        [switch] $BulkProcessing
    )

    $List = @{
        createEnterpriseID = 'createEnterpriseID'
        addAdobeID         = 'addAdobeID'
        createFederatedID  = 'createFederatedID'
    }
    $OptionList = @{
        ignoreIfAlreadyExists = 'ignoreIfAlreadyExists'
        updateIfAlreadyExists = 'updateIfAlreadyExists'
    }
    $OptionConverted = $OptionList[$Option]

    if (-not $Script:AdobeTokenInformation) {
        Write-Warning -Message 'New-AdobeUser - You need to connect to Adobe first using Connect-Adobe'
        return
    }
    # we need to convert the type to the correct format so it preservers problem casing
    $ConvertedType = $List[$Type]
    $Data = [ordered] @{
        user      = $EmailAddress
        requestID = "action_$(Get-Random)"
        do        = @(
            [ordered] @{
                $ConvertedType = [ordered] @{
                    email     = $EmailAddress
                    country   = $Country
                    firstname = $FirstName
                    lastname  = $LastName
                    option    = $OptionConverted
                }
            }
        )
    }
    if ($BulkProcessing) {
        return $Data
    }

    $Data | ConvertTo-Json -Depth 5 | Write-Verbose

    $QueryParameter = [ordered] @{
        testOnly = if ($PSCmdlet.ShouldProcess($EmailAddress, 'Add Adobe User')) {
            $false
        } else {
            $true
        }
    }

    Invoke-AdobeQuery -Url "action" -Method 'POST' -Data $Data -QueryParameter $QueryParameter
}

# PowerForge merged source end cb996f3cbd50496d0c97f4e8e76046b630c690fce2bf0232b10edb252c788074

# PowerForge merged source begin cb996f3cbd50496d0c97f4e8e76046b630c690fce2bf0232b10edb252c788074
function Remove-AdobeGroup {
    <#
    .SYNOPSIS
    Removes an Adobe user group.

    .DESCRIPTION
    The Remove-AdobeGroup cmdlet deletes a specified user group from the Adobe system. It requires an active Adobe connection.

    .PARAMETER Name
    The name of the Adobe group to remove.

    .PARAMETER BulkProcessing
    Switch to enable bulk processing mode.

    .EXAMPLE
    Remove-AdobeGroup -Name "MarketingTeam"
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [alias('GroupName')][Parameter(Mandatory)][string] $Name,
        [switch] $BulkProcessing
    )
    if (-not $Script:AdobeTokenInformation) {
        Write-Warning -Message 'Remove-AdobeGroup - You need to connect to Adobe first using Connect-Adobe'
        return
    }
    $Data = [ordered] @{
        usergroup = $Name
        requestID = "action_$(Get-Random)"
        do        = @(
            [ordered] @{
                'deleteUserGroup' = [ordered] @{ }
            }
        )
    }

    Remove-EmptyValue -Hashtable $Data -Recursive -Rerun 2

    if ($BulkProcessing) {
        return $Data
    }

    $Data | ConvertTo-Json -Depth 5 | Write-Verbose

    $QueryParameter = [ordered] @{
        testOnly = if ($PSCmdlet.ShouldProcess($Name, 'Remove Adobe Group Member')) {
            $false
        } else {
            $true
        }
    }

    Invoke-AdobeQuery -Url "action" -Method 'POST' -Data $Data -QueryParameter $QueryParameter
}
# PowerForge merged source end cb996f3cbd50496d0c97f4e8e76046b630c690fce2bf0232b10edb252c788074

# PowerForge merged source begin cb996f3cbd50496d0c97f4e8e76046b630c690fce2bf0232b10edb252c788074
function Remove-AdobeGroupMember {
    <#
    .SYNOPSIS
    Removes a member from one or more Adobe groups.

    .DESCRIPTION
    The Remove-AdobeGroupMember cmdlet removes a specified user from one or more Adobe groups. Use the -All switch to remove the user from all groups.

    .PARAMETER GroupName
    The name(s) of the Adobe group(s) from which the user will be removed.

    .PARAMETER Email
    The email address of the user to be removed from the group(s).

    .PARAMETER All
    Removes the user from all Adobe groups.

    .EXAMPLE
    Remove-AdobeGroupMember -GroupName "Marketing" -Email "user@example.com"

    .EXAMPLE
    Remove-AdobeGroupMember -All -Email "user@example.com"
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][string[]] $GroupName,
        [Parameter(Mandatory)][string] $Email,
        [switch] $All
    )

    if (-not $Script:AdobeTokenInformation) {
        Write-Warning -Message 'Remove-AdobeGroupMember - You need to connect to Adobe first using Connect-Adobe'
        return
    }
    if ($GroupName.Count -gt 10) {
        Write-Warning -Message 'Remove-AdobeGroupMember - Only ten groups can be added at a time'
        return
    }
    if ($All) {
        $Data = [ordered] @{
            user      = $Email
            requestID = "action_$(Get-Random)"
            do        = @(
                @{
                    'remove' = 'all'
                }
            )
        }
    } else {
        $Data = [ordered] @{
            user      = $Email
            requestID = "action_$(Get-Random)"
            do        = @(
                @{
                    'remove' = @{
                        'group' = @(
                            $GroupName
                        )
                    }
                }
            )
        }
    }

    Remove-EmptyValue -Hashtable $Data -Recursive -Rerun 2

    $Data | ConvertTo-Json -Depth 5 | Write-Verbose

    $QueryParameter = [ordered] @{
        testOnly = if ($PSCmdlet.ShouldProcess($GroupName, 'Remove Adobe Group Member')) {
            $false
        } else {
            $true
        }
    }

    Invoke-AdobeQuery -Url "action" -Method 'POST' -Data $Data -QueryParameter $QueryParameter
}
# PowerForge merged source end cb996f3cbd50496d0c97f4e8e76046b630c690fce2bf0232b10edb252c788074

# PowerForge merged source begin cb996f3cbd50496d0c97f4e8e76046b630c690fce2bf0232b10edb252c788074
function Remove-AdobeUser {
    <#
    .SYNOPSIS
    Removes an Adobe user.

    .DESCRIPTION
    The Remove-AdobeUser cmdlet deletes a specified user from the Adobe system. Optionally, it can also delete the user's account.

    .PARAMETER EmailAddress
    The email address of the Adobe user to remove.

    .PARAMETER DoNotDeleteAccount
    When specified, the user's account will not be deleted, only their association with groups.

    .PARAMETER BulkProcessing
    Switch to enable bulk processing mode.

    .EXAMPLE
    Remove-AdobeUser -EmailAddress "jane.doe@example.com" -DoNotDeleteAccount
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][string] $EmailAddress,
        [switch] $DoNotDeleteAccount,
        [switch] $BulkProcessing
    )
    if (-not $Script:AdobeTokenInformation) {
        Write-Warning -Message 'Remove-AdobeUser - You need to connect to Adobe first using Connect-Adobe'
        return
    }
    $Data = [ordered] @{
        user      = $EmailAddress
        requestID = "action_$(Get-Random)"
        do        = @(
            [ordered] @{
                'removeFromOrg' = [ordered] @{
                    deleteAccount = -not $DoNotDeleteAccount.IsPresent
                }
            }
        )
    }

    Remove-EmptyValue -Hashtable $Data -Recursive -Rerun 2

    if ($BulkProcessing) {
        return $Data
    }

    $Data | ConvertTo-Json -Depth 5 | Write-Verbose

    $QueryParameter = [ordered] @{
        testOnly = if ($PSCmdlet.ShouldProcess($EmailAddress, 'Remove Adobe User')) {
            $false
        } else {
            $true
        }
    }

    Invoke-AdobeQuery -Url "action" -Method 'POST' -Data $Data -QueryParameter $QueryParameter
}
# PowerForge merged source end cb996f3cbd50496d0c97f4e8e76046b630c690fce2bf0232b10edb252c788074

# PowerForge merged source begin cb996f3cbd50496d0c97f4e8e76046b630c690fce2bf0232b10edb252c788074
function Set-AdobeGroup {
    <#
    .SYNOPSIS
    Updates an Adobe user group.

    .DESCRIPTION
    The Set-AdobeGroup cmdlet updates the name and/or description of an existing Adobe user group.

    .PARAMETER Name
    The current name of the Adobe group to update.

    .PARAMETER NewName
    The new name for the Adobe group.

    .PARAMETER Description
    The new description for the Adobe group.

    .PARAMETER BulkProcessing
    Switch to enable bulk processing mode.

    .EXAMPLE
    Set-AdobeGroup -Name "Developers" -NewName "Senior Developers" -Description "Group for senior developer roles"
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][string] $Name,
        [Parameter()][string] $NewName,
        [Parameter()][string] $Description,
        [switch] $BulkProcessing
    )
    if (-not $Script:AdobeTokenInformation) {
        Write-Warning -Message 'Set-AdobeGroup - You need to connect to Adobe first using Connect-Adobe'
        return
    }
    if (-not $NewName -and -not $Description) {
        Write-Warning -Message 'Set-AdobeGroup - You need to provide either a new name or a description'
        return
    }

    $Data = [ordered] @{
        usergroup = $Name
        requestID = "action_$(Get-Random)"
        do        = @(
            [ordered] @{
                'updateUserGroup' = [ordered] @{
                    name        = $NewName
                    description = $Description
                }
            }
        )
    }

    Remove-EmptyValue -Hashtable $Data -Recursive -Rerun 2

    if ($BulkProcessing) {
        return $Data
    }

    $Data | ConvertTo-Json -Depth 5 | Write-Verbose

    $QueryParameter = [ordered] @{
        testOnly = if ($PSCmdlet.ShouldProcess($Name, 'Set Adobe Group')) {
            $false
        } else {
            $true
        }
    }

    Invoke-AdobeQuery -Url "action" -Method 'POST' -Data $Data -QueryParameter $QueryParameter
}
# PowerForge merged source end cb996f3cbd50496d0c97f4e8e76046b630c690fce2bf0232b10edb252c788074

# PowerForge merged source begin cb996f3cbd50496d0c97f4e8e76046b630c690fce2bf0232b10edb252c788074
function Set-AdobeUser {
    <#
    .SYNOPSIS
    Update Adobe User information using Adobe API

    .DESCRIPTION
    Update Adobe User information using Adobe API. Applies only to Enterprise and Federated users.
    Independent Adobe IDs are managed by the individual user and cannot be updated through the User Management API.
    Attempting to update information for a user who has an Adobe ID will result in an error.

    .PARAMETER EmailAddress
    The current email address of the Adobe user to update.

    .PARAMETER NewEmailAddress
    The new email address for the Adobe user.

    .PARAMETER Country
    The country of the Adobe user.

    .PARAMETER FirstName
    The first name of the Adobe user.

    .PARAMETER LastName
    The last name of the Adobe user.

    .PARAMETER UserName
    The username of the Adobe user.

    .PARAMETER BulkProcessing
    Switch to enable bulk processing mode.

    .EXAMPLE
    Set-AdobeUser -EmailAddress 'przemek@test.pl' -NewEmailAddress 'przemek@test1.pl' -LastName 'Klys' -WhatIf -Verbose
    $SetInformation

    .NOTES
    General notes
    #>
    [cmdletbinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][string] $EmailAddress,
        [string] $NewEmailAddress,
        [string] $Country,
        [string] $FirstName,
        [string] $LastName,
        [string] $UserName,
        [switch] $BulkProcessing
    )

    if (-not $Script:AdobeTokenInformation) {
        # Ensure Adobe is connected before proceeding
        Write-Warning -Message 'Set-AdobeUser - You need to connect to Adobe first using Connect-Adobe'
        return
    }

    $UpdateObject = [ordered] @{
        "update" = [ordered] @{
            email     = $NewEmailAddress
            country   = $Country
            firstname = $FirstName
            lastname  = $LastName
            username  = $UserName
        }
    }

    # Remove any empty values from the update object
    Remove-EmptyValue -Hashtable $UpdateObject -Recursive -Rerun 2
    if (-not $UpdateObject) {
        # Warn if no update values are provided
        Write-Warning -Message 'Set-AdobeUser - You need to provide at least one value to update'
        return
    }
    $Data = [ordered] @{
        user      = $EmailAddress
        requestID = "action_$(Get-Random)"
        do        = @(
            $UpdateObject
        )
    }

    if ($BulkProcessing) {
        # Return data for bulk processing
        return $Data
    }

    $Data | ConvertTo-Json -Depth 5 | Write-Verbose

    $QueryParameter = [ordered] @{
        testOnly = if ($PSCmdlet.ShouldProcess($EmailAddress, 'Update Adobe User')) {
            $false
        } else {
            $true
        }
    }

    # Invoke the Adobe API with the prepared data
    Invoke-AdobeQuery -Url "action" -Method 'POST' -Data $Data -QueryParameter $QueryParameter
}
# PowerForge merged source end cb996f3cbd50496d0c97f4e8e76046b630c690fce2bf0232b10edb252c788074

$FunctionsToExport = @('Add-AdobeGroupMember', 'Connect-Adobe', 'Get-AdobeGroup', 'Get-AdobeGroupMember', 'Get-AdobeUser', 'Invoke-AdobeBulk', 'New-AdobeGroup', 'New-AdobeUser', 'Remove-AdobeGroup', 'Remove-AdobeGroupMember', 'Remove-AdobeUser', 'Set-AdobeGroup', 'Set-AdobeUser')
$CmdletsToExport = @()
$AliasesToExport = @('Add-AdobeUser')
Export-ModuleMember -Function $FunctionsToExport -Alias $AliasesToExport -Cmdlet $CmdletsToExport
