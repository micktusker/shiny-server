function SequenceHydrophobicity(aaSequence) {
    'use strict';
    this.aaSequence = aaSequence;
    // #FF0000 = red, #FFA500 = #orange, acqua = #00FFFF,  #0000FF = blue
    this.aaHydropathyMap = {
        "I": {"hydropathy": 4.5,  "color": "#FF0000"},
        "V": {"hydropathy": 4.2,  "color": "#FF0000"},
        "L": {"hydropathy": 3.8,  "color": "#FF0000"},
        "F": {"hydropathy": 2.8,  "color": "#FF0000"},
        "C": {"hydropathy": 2.5,  "color": "#FF0000"},
        "M": {"hydropathy": 1.9,  "color": "#FFA500"},
        "A": {"hydropathy": 1.8,  "color": "#FFA500"},
        "G": {"hydropathy": -0.4,  "color": "#00FFFF"},
        "T": {"hydropathy": -0.7,  "color": "#00FFFF"},
        "S": {"hydropathy": -0.8,  "color": "#00FFFF"},
        "W": {"hydropathy": -0.9,  "color": "#00FFFF"},
        "Y": {"hydropathy": -1.3,  "color": "#00FFFF"},
        "P": {"hydropathy": -1.6,  "color": "#00FFFF"},
        "H": {"hydropathy": -3.2,  "color": "#0000FF"},
        "N": {"hydropathy": -3.5,  "color": "#0000FF"},
        "D": {"hydropathy": -3.5,  "color": "#0000FF"},
        "E": {"hydropathy": -3.5,  "color": "#0000FF"},
        "Q": {"hydropathy": -3.5,  "color": "#0000FF"},
        "K": {"hydropathy": -3.9,  "color": "#0000FF"},
        "R": {"hydropathy": -4.5,  "color": "#0000FF"}
    };
}

SequenceHydrophobicity.prototype = {
    constructor: SequenceHydrophobicity,
    getHydrophobicityMarkedupSequence: function () {
        var aa,
            markedUpSequence = '',
            colorForSequence,
            markedUpAA;
        for ( var i = 0; i < this.aaSequence.length; i += 1) {
            aa = this.aaSequence[i];
            colorForSequence = this.aaHydropathyMap[aa].color;
            markedUpAA = '<span style="background-color:' + colorForSequence + '">'  + aa + '</span>';
            markedUpSequence += markedUpAA;
        }
        return markedUpSequence;    
    }
};

function writeMarkedUpSequenceResults() {
    var seq = document.getElementById("aa_sequence").value.trim().toUpperCase(),
        seqMarkupObj = new SequenceHydrophobicity(seq),
        hydrophobicityMarkedupSequence = seqMarkupObj.getHydrophobicityMarkedupSequence(),
        targetDiv = document.getElementById("seq_hydrophobicity");
    targetDiv.innerHTML = '<p><span style="font-family:monospace">' + seq + '<br>' + hydrophobicityMarkedupSequence + '</span></p>';
}
