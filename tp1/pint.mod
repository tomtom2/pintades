set PROP ordered;
set ELEVAGE ordered;
set TRANSPORT ordered;
set FURNITURES ordered;
set STRUCTURES ordered;


param age_eclosion {j in PROP} >= 0, default 0;
param age_ponte {j in PROP} >= age_eclosion[j], default 3;
param age_vieillesse {j in PROP} >= age_ponte[j], default 9;
param age_mort {j in PROP} >= age_vieillesse[j], default 12;

param qtt_gardee {j in ELEVAGE} >= 0, default Infinity;
param qtt_vendu_max {j in ELEVAGE} <= qtt_gardee[j];
param age_vente_min {j in ELEVAGE} >= 0, default 0;
param age_vente_max {j in ELEVAGE} >= 0, default 0;
param conso_grain {j in ELEVAGE} >= 0, default 0;
param prix {j in ELEVAGE} >= 0, default 0;
param prix_oeuf {j in ELEVAGE} >= 0, default 0;

param qtt_trans {j in TRANSPORT} >= 0, default 0;
param cost_trans {j in TRANSPORT} >= 0, default 0;
param capacity {j in TRANSPORT} >= 0, default 0;
param travel_cost {j in TRANSPORT} >= 0, default 0;

param qtt_grain {j in FURNITURES} >= 0, default 0;
param cost_grain {j in FURNITURES} >= 0, default 0;

param surface_max {j in STRUCTURES} >= 0, default 0;
param cost_per_metre {j in STRUCTURES} >= 0, default 0;

param pintades_space {STRUCTURES,ELEVAGE} >= 0, default 0;

param pintades_food {FURNITURES,ELEVAGE} >= 0, default 0;

# --------------------------------------------------------

var pintades_age {j in ELEVAGE, 0..age_mort['pintade']} integer >= 0 ;

var Ventes {i in ELEVAGE, 0..age_mort['pintade']} integer >= 0, <= qtt_vendu_max[i] ;

var achat_grain {i in FURNITURES} >= 0, <= 99999999999 ;

#var transport {t in TRANSPORT} integer >= 0, <= qtt_trans[t] ;

var voyages {TRANSPORT} integer >= 0, <= 80 ;

var surface {s in STRUCTURES} integer >= 0, <= surface_max[s] ;

var investments = sum {s in STRUCTURES} surface[s] * cost_per_metre[s] + sum {t in TRANSPORT} qtt_trans[t] * cost_trans[t] ;

# --------------------------------------------------------

maximize Benefits : sum {j in ELEVAGE, age in age_eclosion['pintade']..age_vieillesse['pintade']} Ventes[j, age] * prix[j] + sum {j in ELEVAGE, age in 0..age_eclosion['pintade']} Ventes[j, age] * prix_oeuf[j] - sum {i in FURNITURES} achat_grain[i] * cost_grain[i] - sum {t in TRANSPORT} voyages[t] * travel_cost[t] * qtt_trans[t] ;

minimize Investments : investments;

# --------------------------------------------------------

#
# la repartition des pintades par tranches d'age est constante
#
subject to repartition_age {i in ELEVAGE, j in 0..age_mort['pintade']-1}: pintades_age[i,j+1] <= pintades_age[i,j] - Ventes[i, j];

subject to repartition_age_ponte {i in ELEVAGE}: pintades_age[i,0] = sum {age_pondeuse in age_ponte['pintade']..age_mort['pintade']} (pintades_age[i,age_pondeuse] - Ventes[i, age_pondeuse]);


#
# le nombre de pintades est limité par la surface disponible
#
subject to plafond {s in STRUCTURES} : sum {i in ELEVAGE, j in age_eclosion['pintade']..age_mort['pintade']} pintades_age[i, j] * pintades_space[s,i] <= surface[s];

#
# le nombre de pintades vendues est inferieur au nombre de pintades présentes
#
subject to ventes_max {i in ELEVAGE, j in 0..age_mort['pintade']}: Ventes[i, j] <= pintades_age[i,j];

#
# on doit acheter (et aller chercher) sufisemment de grain pour nourrir toutes les pintades
#
subject to food_required {i in FURNITURES}: achat_grain[i] >= sum {j in ELEVAGE, age in age_eclosion['pintade']..age_mort['pintade']} (pintades_age[j, age] - Ventes[j, age]) * pintades_food[i,j] * conso_grain[j] ;

#
# on doit faire assez de voyages
#
subject to travel_for_food_required: sum {t in TRANSPORT} voyages[t] * capacity[t] * qtt_trans[t]  >= sum {i in FURNITURES} achat_grain[i] ;

#
# on doit respecter les conditions de ventes sur l'age minimum:
#
subject to label_requirments: sum {i in ELEVAGE} sum {j in age_eclosion['pintade']..age_vente_min[i]} Ventes[i, j]  = 0 ;
