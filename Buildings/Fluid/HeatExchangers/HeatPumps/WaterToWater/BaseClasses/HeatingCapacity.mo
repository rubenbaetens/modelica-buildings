within Buildings.Fluid.HeatExchangers.HeatPumps.WaterToWater.BaseClasses;
block HeatingCapacity
  "Calculates heating and cooling capacities for different stages"
  extends
    Buildings.Fluid.HeatExchangers.HeatPumps.WaterToWater.BaseClasses.InputInterface;
  parameter
    Buildings.Fluid.HeatExchangers.HeatPumps.WaterToWater.Data.BaseClasses.HeatingMode
    heaMod "Performance data";

  output Modelica.SIunits.Temperature T_nominal "Reference temperature";
//   output Modelica.SIunits.MassFlowRate m1_flow_nominal = heaMod.m1_flow_nominal
//     "Medium1 nominal mass flow rate";
//   output Modelica.SIunits.MassFlowRate m2_flow_nominal = heaMod.m2_flow_nominal
//     "Medium2 nominal mass flow rate";
  output Real T1_NonDim "Medium1 non-dimensional temperature";
  output Real T2_NonDim "Medium2 non-dimensional temperature";
  output Real V1_flow_NonDim "Medium1 non-dimensional volumetric flow rate";
  output Real V2_flow_NonDim "Medium2 non-dimensional volumetric flow rate";
  output Real NonDimVarSet[4]={T1_NonDim,T2_NonDim,V1_flow_NonDim,V2_flow_NonDim}
    "Set of non-dimensional variables";

  output Real fra1(min=0, max=1)
    "Fraction for zero and reverse flow condition on load side";
  output Real fra2(min=0, max=1)
    "Fraction for zero and reverse flow condition on source side";
  output Real fra(min=0, max=1) "Fraction for zero and reverse flow condition";
  constant Real deltaV_flow_NonDim=0.0001
    "Minimum non-dimensional volumetric flow rate below which heat transfer stops";
                                          //below 0.0001 fra1 and fra2 are not 0 and 1
    //delta for non-dimensional variable which varies between 0 and 1 thus non relative value

  Modelica.Blocks.Interfaces.RealOutput QHea1_flow[heaMod.nSta](unit="W")
    "Vol1 heat transfer rate"
    annotation (Placement(transformation(extent={{100,30},{120,50}})));

  Modelica.Blocks.Interfaces.RealOutput PHea[heaMod.nSta](quantity="Power", unit="W")
    "Electrical power consumed by the compressor"
    annotation (Placement(transformation(extent={{100,-50},{120,-30}},
                                                                     rotation=0)));

equation
  if mode == 1 then
  //Determine nominal temperature to be used
    T_nominal= heaMod.T_nominal;
  //Determine nominal mass flow rates to be used
//     m1_flow_nominal= heaMod.m1_flow_nominal;
//     m2_flow_nominal= heaMod.m2_flow_nominal;
  //Calculate non-dimensional variables
    T1_NonDim= T1/T_nominal;
    T2_NonDim= T2/T_nominal;
  // fixme: multiply by density fraction
    V1_flow_NonDim= (m1_flow/heaMod.m1_flow_nominal)*(rho[3]/rho[1]);
    V2_flow_NonDim= (m2_flow/heaMod.m2_flow_nominal)*(rho[4]/rho[2]);

  //Fractions for zero and reverse mass flow rate
    fra1= Buildings.Utilities.Math.Functions.spliceFunction(
      pos=1,
      neg=0,
      x=V1_flow_NonDim - deltaV_flow_NonDim,
      deltax=deltaV_flow_NonDim);
    fra2= Buildings.Utilities.Math.Functions.spliceFunction(
      pos=1,
      neg=0,
      x=V2_flow_NonDim - deltaV_flow_NonDim,
      deltax=deltaV_flow_NonDim);
    fra= fra1*fra2;

    for iSta in 1:heaMod.nSta loop
    //Heating mode calculations
      QHea1_flow[iSta] =
        Buildings.Fluid.HeatExchangers.HeatPumps.WaterToWater.BaseClasses.linearFourVariables(
         x=NonDimVarSet, a=heaMod.heaPer[iSta].heaCap)*heaMod.heaPer[iSta].QHea_flow_nominal
        *fra;
      PHea[iSta] =
        Buildings.Fluid.HeatExchangers.HeatPumps.WaterToWater.BaseClasses.linearFourVariables(
         x=NonDimVarSet, a=heaMod.heaPer[iSta].heaP)*heaMod.heaPer[iSta].PHea_nominal
        *fra;
    end for;
  else //Compressor off condition
    T_nominal= 273.15;
//     m1_flow_nominal= 0;
//     m2_flow_nominal= 0;
    T1_NonDim= 0;
    T2_NonDim= 0;
    V1_flow_NonDim= 0;
    V2_flow_NonDim= 0;
    QHea1_flow= fill(0, heaMod.nSta);
    PHea= fill(0, heaMod.nSta);
    fra1= 0;
    fra2= 0;
    fra= 0;
  end if;
  annotation (defaultComponentName="heaCap", Diagram(graphics), Documentation(info="<html>
<p>
This block calculates the rate of heating for the water on load side.
The model is based on four non-dimensional variables to calculate the heat pump performance. 
For more details abot the model refer to dissertation by Tang (2005)</p>
<p>
The equations used to calcualte the performance are:
<p align=\"center\" style=\"font-style:italic;\">
  Q&#775;<sub> h </sub>  &frasl;  Q&#775;<sub> h, nom </sub> = c<sub>1</sub>
      + c<sub>2</sub> (T<sub>l,in </sub> &frasl;  T<sub>nom </sub>)
      + c<sub>3</sub> (T<sub>s,in </sub> &frasl;  T<sub>nom </sub>)
      + c<sub>4</sub> (V&#775;<sub>l,in </sub> &frasl;  V&#775;<sub>l,nom </sub>)
      + c<sub>5</sub> (V&#775;<sub>s,in </sub> &frasl;  V&#775;<sub>s,nom </sub>)</p>
<p align=\"center\" style=\"font-style:italic;\">
  P<sub> h </sub>  &frasl;  P<sub> h, nom </sub> = d<sub>1</sub>
      + d<sub>2</sub> (T<sub>l,in </sub> &frasl;  T<sub>nom </sub>)
      + d<sub>3</sub> (T<sub>s,in </sub> &frasl;  T<sub>nom </sub>)
      + d<sub>4</sub> (V&#775;<sub>l,in </sub> &frasl;  V&#775;<sub>l,nom </sub>)
      + d<sub>5</sub> (V&#775;<sub>s,in </sub> &frasl;  V&#775;<sub>s,nom </sub>)</p>

where, subcripts <i>l</i> stands for load side values, 
<i>s</i> stands for source side values, 
<i>nom</i> stands for nominal values, 
<i>h</i> stands for heating. The coefficients 
<i>c<sub>1</sub></i> to <i>c<sub>5</sub></i>, 
and <i>d<sub>1</sub></i> to <i>d<sub>5</sub></i>, are calculated using manufacturers data.  
</p>
<h4>References</h4>
<p>
Tang, Chin Chien.
Modeling Packaged Heat Pumps in a Quasi-Steady State Energy Simulation Program.
<i>Oklahoma State University</i>, Stillwater, Oklahoma, May, 2005.
</p>
</html>",
revisions="<html>
<ul>
<li>
Jan 10, 2013 by Kaustubh Phalak:<br>
First implementation. 
</li>
</ul>

</html>"),Icon(graphics), Diagram(graphics));
end HeatingCapacity;