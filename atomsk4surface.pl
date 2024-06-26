#!/usr/bin/perl

#"[010] [001] [100]";# 100 crystal axis vectors,
#"[001] [1-10] [110]";# 110 crystal axis vectors,x 2
#"[1-21] [10-1] [111]";# 111 crystal axis vectors, x6
use strict;
use warnings;
use Cwd;

my $currentPath = getcwd();# dir for all scripts
chdir("..");
my $mainPath = getcwd();# main path of Perl4dpgen dir
chdir("$currentPath");

my %scale = (
    111 => 5,#scale 1/5 z length of cell
    110 => 2,# x 2
    100 => 1
);

my $rcut = 6 + 1; #Your DLP rcut + 2 to cut the plane by atomsk
my $source = "$currentPath/data4surface";
my $des = "$currentPath/surface_data";

my @surfaceZ = (#set planes as many as you like!
    '[100]',
    '[110]',
    '[111]'
);

my @sur_name = map {s/[\[\]]//g; $_} @surfaceZ;

`rm -rf $des`;
`mkdir -p $des`;

my @source_data = `find -L $source -mindepth 1 -maxdepth 1 -type f -name "*.data" `;
map { s/^\s+|\s+$//g; } @source_data;

for my $file (@source_data) {
    my $basename = `basename $file`;
    my $dirname = `dirname $file`;
    $basename =~ s/^\s+|\s+$//g;
    $dirname =~ s/^\s+|\s+$//g;
    $basename =~ s/\.data//g;

    #get atom type number
    my $typeNo = `grep "atom types" $file|awk '{print \$1}'`;
    $typeNo =~ s/^\s+|\s+$//g;
    my @masses = `grep -v '^[[:space:]]*\$' $file|grep -A $typeNo Masses|grep -v Masses|grep -v -- '--'`;
    map { s/^\s+|\s+$//g; } @masses;
    my $masses = join("\n",@masses);
    #print "$typeNo\n, $masses\n";
    #die;
    `rm -f $dirname/$basename.lmp`;#for atomsk only
    `cp $dirname/$basename.data $dirname/$basename.lmp`;#for atomsk only

    for my $i (0..$#sur_name){
        `rm -f $dirname/$basename-$sur_name[$i].lmp`;
        my $command = "atomsk $dirname/$basename.lmp -cut above $rcut $surfaceZ[$i] $des/$basename-$sur_name[$i].lmp";
        #my $command = "atomsk $dirname/$basename.lmp -orient [100] [010] [001] $surfaceZ[$i] -orthogonal-cell -reduce-cell $des/$basename-$sur_name[$i].lmp";
        system("$command");
        `sed -i '/atom types/c\ $typeNo atom types' $des/$basename-$sur_name[$i].lmp`;
        my @part1 = `grep -B 100000 Masses $des/$basename-$sur_name[$i].lmp`;
        map { s/^\s+|\s+$//g; } @part1;
        my $part1 = join("\n",@part1);
        my @part2 = `grep -A 100000 Atoms $des/$basename-$sur_name[$i].lmp`;
        map { s/^\s+|\s+$//g; } @part2;
        my $part2 = join("\n",@part2);
        
        my $assemble = "$part1\n\n"."$masses\n\n"."$part2\n";
        print "$assemble\n";
        #`touch $des/$basename-$sur_name[$i].lmp`;
        `echo "$assemble" > $des/$basename-$sur_name[$i].lmp`;         

        #system("atomsk $des/$basename-$sur_name[$i].lmp -cut above $ref_hi z $des/$basename-$sur_name[$i]_cut.lmp");
        #`rm -f $des/$basename-$sur_name[$i].lmp`;

        #my $final_zhi = $ref_hi + $rcut;
        #my $box = "$final_zhi z ";
        ##my $box = "$x[0] $x[1] $y[0] $y[1] $z[0] $final_zhi ";
        #`sed -i '/zlo zhi/c\  $z[0]  $final_zhi zlo zhi' $des/$basename-$sur_name[$i]_cut.lmp`;
        `mv $des/$basename-$sur_name[$i].lmp $des/$basename-$sur_name[$i].data`;
        #`rm -f $des/$basename-$sur_name[$i]_cut.lmp`;
#
    }#
    `rm -f $des/$basename.lmp`;#remove old
    `rm -f $dirname/$basename.lmp`;
}

