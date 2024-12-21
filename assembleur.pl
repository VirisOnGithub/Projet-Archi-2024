use strict;
use warnings;

# La hashmap "ops" sert à donner les bons codes binaires pour chacunes des opérations

my %ops = (
    # Opération UAL
    "ADD"  => "000",
    "ADDi" => "000",
    "SUB"  => "001",
    "SUBi" => "001",
    "MUL"  => "010",
    "MULi" => "010",
    "AND"  => "011",
    "ANDi" => "011",
    "OR"   => "100",
    "ORi"  => "100",
    "XOR"  => "101",
    "XORi" => "101",
    "SL"   => "110",
    "SLi"  => "110",
    "SR"   => "111",
    "SRi"  => "111",

    # Opérations MEM
    "ST" => "000",
    "LD" => "001",

    # Opérations CTRL
    "JMP"  => "000",
    "JSUP" => "001",
    "JEQU" => "010",
    "JNEQ" => "011",
    "JINF" => "100",
    "CALL" => "101",
    "RET"  => "110",
    "STOP" => "111"
);

my $hasStop = 0; # Test si le fichier finit bien, en regardant si l'instruction "STOP" y apparaît

# En perl, la variable "$_" est une variable par défaut, donc les syntaxes suivantes créent des hashmap
# avec pour clé chacun des éléments susmentionnés et 1 comme valeur
# En réalité, leur seule utilité est de tester quelle est la catégorie de chaque opération
my %opUAL = map { $_ => 1 } (
    "ADD",  "SUB",  "MUL", "OR",   "XOR",  "AND", "SL",  "SR",
    "ADDi", "SUBi", "ORi", "XORi", "ANDi", "SLi", "SRi", "MULi"
);
my %opMEM = map { $_ => 1 } ( "ST", "LD" );
my %opCTRL = map { $_ => 1 } ( 
    "JMP", "JEQU", "JNEQ", "JSUP", "JINF", "CALL", "RET", "STOP" 
);

my %labelsMap; # Initialisation de la hashmap qui contiendra l'adresse correspondante à chaque label

# Encodage des registres
my %regs = (
    "R0" => "000",
    "R1" => "001",
    "R2" => "010",
    "R3" => "011",
    "R4" => "100",
    "R5" => "101",
    "R6" => "110",
    "R7" => "111"
);

# Cette fonction renvoie le code de la catégorie d'opération (UAL, MEM, CTRL)
sub sectionCode {
    my $opcode = shift; # récupère l'instruction
    die "Unknown opcode $opcode" unless exists $ops{$opcode};
    return "00" if exists $opUAL{$opcode};  # 00 pour les opérations arithmétiques et logiques
    return "01" if exists $opMEM{$opcode};  # 01 pour les opérations de mémoire
    return "11" if exists $opCTRL{$opcode}; # 11 pour les opérations de contrôle
    die "Unknown section for opcode $opcode"; # Uniquement à des fins de sécurité
}

# Convertit correctement chaque instruction en hexa
sub binToHex {
    my $bin       = shift;
    my @bin_array = ( $bin =~ /.{1,4}/g ); # On divise en "mots" de 4 chiffres
    my $hex = "";
    foreach my $bin (@bin_array) {
        $hex .= sprintf( "%X", oct("0b$bin") );
    }
    return $hex;
}

my ($fileEntry, $fileExit);
if(scalar @ARGV == 0){
    $fileEntry = "input.txt";
    $fileExit  = "output.txt";
} elsif (scalar @ARGV == 2){
    ($fileEntry, $fileExit) = @ARGV
} else {
    system('echo -e "\e[31;1mNombre de paramètres incorrects\e[0m" ');
    die "\n";
}
unless (-e $fileEntry){
    system('echo -e "\e[31;1mFichier d\'entrée inexistant\e[0m" ');
    die "\n";
}
system("touch $fileExit")  unless -e $fileExit;
open( my $fh, "<", $fileEntry ) or die "Can't open < $fileEntry: $!";
open( my $fe, ">", $fileExit )  or die "Can't open > $fileExit: $!";

print $fe "v3.0 hex words addressed\n";
my $nbLines = 0;

# On va parcourir une première fois le fichier à la recherche de labels
while (<$fh>) {
    chomp;
    next if $_ eq "";
    my @line   = split(' ');
    my $opcode = $line[0];

    # Labels detection
    if ( substr( $opcode, -1 ) eq ":" ) {
        my $label = substr( $opcode, 0, -1 );
        $labelsMap{$label} = sprintf( "%0.16b", $nbLines );
    }
    $nbLines++;
}

# On remet le curseur au premier caractère de la première ligne
seek( $fh, 0, 0 );
$nbLines = 0;

# On parcourt une deuxième fois pour encoder les instructions
while (<$fh>) {
    chomp;
    next if $_ eq "";
    my @line = split(' ');
    my $bin;

    my $opcode = $line[0];

    # Labels detection
    if ( substr( $opcode, -1 ) eq ":" ) {
        @line   = @line[ 1 .. $#line ];
        $opcode = $line[0];
    }
    my $sectionCode = sectionCode($opcode);    # 2 bits
    my $op          = $ops{$opcode};           # 3 bits
    if ( exists $opUAL{$opcode} ) {
        my $i    = ( $opcode =~ /i$/ ) ? 1 : 0;
        my $reg1 = $regs{ $line[1] };
        my $reg2 = $regs{ $line[2] };
        my $reg3 = ( $i == 0 ) ? $regs{ $line[3] }             : "000";
        my $cste = ( $i == 1 ) ? sprintf( "%0.16b", $line[3] ) : "0" x 16;
        $bin = $cste . "0" . $reg3 . $reg2 . $reg1 . $i . $op . $sectionCode;
    }
    elsif ( exists $opMEM{$opcode} ) {
        my $reg1 = $regs{ $line[1] };
        my $reg2 = $regs{ $line[2] };
        # On inverse l'ordre des registres pour respecter la syntaxe : LD R0 R1 <=> R0 := MEM[R1]
        $bin = "0" x 17 . $reg1 . $reg2 . "0000" . $op . $sectionCode;
    }
    elsif ( exists $opCTRL{$opcode} ) {
        if ( $opcode eq "RET" ) {
            $bin = "0" x 27 . $op . $sectionCode;
        }
        elsif ( $opcode eq "CALL" || $opcode eq "JMP" ) {
            my $label = $line[1];
            unless ( exists $labelsMap{$label} ) {
                system('echo -e "\e[31;1mLigne '. ($nbLines+1) .' : Label \"' . $label . '\" inexistant\e[0m" ');
                die "\n";
            }
            $bin = $labelsMap{$label} . "0" x 11 . $op . $sectionCode;
        }
        elsif ( $opcode eq "STOP" ) {
            $hasStop = 1;
            $bin = "1" x 32;
        }
        else {
            my $reg1  = $regs{ $line[1] };
            my $reg2  = $regs{ $line[2] };
            my $label = $line[3];
            $bin = $labelsMap{$label}
              . "0"
              . $reg2
              . $reg1 . "0000"
              . $op
              . $sectionCode;
        }
    }
    else {
        die "Unknown operation $opcode";
    }

    my $hex = binToHex($bin);

    # Mettre les informations au format souhaité

    print $fe sprintf( "%0.4X", $nbLines ) . ": " if $nbLines % 8 == 0;
    print $fe $hex;
    print $fe ( $nbLines % 8 == 7 ) ? "\n" : " ";
    $nbLines++;

}
if(!($hasStop)){
    system('echo -e "\e[33;1mLigne '. $nbLines .' : Aucune balise STOP détectée\e[0m" ');
    die "\n";
}

# Si tout s'est bien déroulé
system('echo -e "\e[32;1mFichier généré avec succès\e[0m" ');