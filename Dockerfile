FROM intel/oneapi-hpckit

WORKDIR /

RUN apt-get update
RUN apt-get install -y curl
RUN apt-get install -y wget zip dos2unix python3

RUN pip3 install pandas
RUN pip3 install matplotlib
RUN pip3 install descartes
RUN pip3 install shapefile
RUN pip3 install pyshp

COPY szip szip
COPY h5fortran h5fortran
COPY zlib-ng-2.0.6.tar.gz /build/hdf5/ZLIB-prefix/src/2.0.6.tar.gz
COPY hdf5-hdf5-1_12_1.tar.gz /build/hdf5/HDF5-prefix/src/hdf5-1_12_1.tar.gz
COPY heclib heclib
COPY iwfm iwfm
COPY iwfm2obs iwfm2obs
COPY build.sh /build.sh

COPY runner/GW_Obs.smp /Simulation/GW_Obs.smp
COPY runner/iwfm2obs_2015.in /Simulation/iwfm2obs_2015.in
COPY runner/MultiLayerTarget.in /Simulation/MultiLayerTarget.in
COPY runner/ObservationConstruction.txt /Simulation/ObservationConstruction.txt
COPY runner/settings.fig /Simulation/settings.fig
COPY runner/STR_Obs.smp /Simulation/STR_Obs.smp
COPY run.sh /run.sh

RUN /build.sh

ENTRYPOINT /run.sh