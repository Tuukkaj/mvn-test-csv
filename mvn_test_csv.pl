#! /usr/bin/perl

# Copyright 2018 Tuukka Juusela

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

# This program is used to turn mvn junit test results to CSV file format. 
# CSV has data for total tests, problems, problem percentage 
# and list of failed tests.

use English; 
use strict; 

# Description: Used to test if given parameter is a failed test.
# Returns failed test's name if fits to regex and zero if not. 
# Input: Line of text from file to test. 
# Output: 0 if does not match regex. Failed test's name
# parsed from line if fits regex.
sub checkTestName($) 
{
    my $temporal;
    if(/(\w+\(\w+\)):\sexpected:<\d+>\sbut\swas:<\d+>/) {
        $temporal = $1;
        return $temporal;
    }
    
    return 0;
}

# Description: Checks if given parameter is info about tests run and problems. 
# Gets called multiple times per file because of identical lines in mvn test. 
# Input: Line of text from a file to test. 
# Output: Returns total number of tests completed, number of problems
# fail percentage.
sub checkTestsAmount($) 
{
    my @list; 
    my ($total, $problems, $failureRate);
    if(/Tests\s+run:\s(\d+),\s\w+:\s(\d+),\s\w+:\s(\d+),\s\w+:\s(\d+)/) {
        $problems = ($2+$3+$4);
        $total = $1; 
        push @list, $total;
        push @list, $problems;
        
        if($problems ne 0 | $total ne 0) {
            $failureRate = $problems / $total * 100; 
            $failureRate = sprintf "%.0f", $failureRate; 
        } else {
            $failureRate = 0; 
        }
        push @list, $failureRate;
        
        return @list;
    }
    
    return 0;
}

# Description: Turns parameters to CSV data. 
# Input: First $: number of total tests, Second $: number of total probelems in
# tests, third $: Problem percentage in tests and fourth @: list of 
# failed tests in the file.  
# Output: Prints ready to use CSV file. 
sub printCSV($$$@) 
{
    my($total, $problems, $problemPercentage, @failedTests) = @ARG;
    my ($csvTitles, $values); 
    
    $csvTitles = "tests, problems, problem percentage, failed tests";
    $values .= $total;
    $values .= ","; 
    $values .= $problems; 
    $values .= ","; 
    $values .= $problemPercentage;
    $values .= ",";     
    
    if(@failedTests > 0) {
        $values .= "\"";
        
        for (my $i=0; $i < @failedTests; $i++) {
            if($i < @failedTests-1) {
                $values .= $failedTests[$i];
                $values .= ","; 
            } else {
                $values .= $failedTests[$i];
            }
        }
        
        $values .= "\"\n";
        
    } else {
        $values .= "No failed tests";
    }
    
    # First line printed is for titles in a spreadsheet. 
    # Second line printed is for values. 
    print"$csvTitles\n$values";
    
}

# Description: Goes through given file line by line. 
# Gets all of the failed tests and total tests run, problem amount, 
# problem percentage. 
# Input: No inputs. 
# Output: Prints ready to use CSV file. 
sub Main() 
{
    my @failedTests; 
    my($total, $problems, $failureRate);
    while(<>) {
        chomp; 
        
        if(checkTestName($ARG) ne 0) {
            my($problem) = checkTestName($ARG); 
            push @failedTests, $problem;
            
        # This if statement is true multiple times because of mvn tests output
        # has identical lines. Over writes values multiple times. 
        # Last line that fits to the regex is the summary of all tests. 
        } elsif(checkTestsAmount($ARG) ne 0) {
            my @tempList = checkTestsAmount($ARG); 
            $total = $tempList[0];
            $problems = $tempList[1];
            $failureRate = $tempList[2];
        }
    }
    
    # Used to turn files data to CSV. 
    printCSV($total, $problems, $failureRate, @failedTests); 
}

Main(); 
# End of file