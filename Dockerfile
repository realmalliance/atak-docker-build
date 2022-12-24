FROM ubuntu:focal

RUN ln -fs /usr/share/zoneinfo/America/New_York /etc/localtime
RUN apt-get update -y && apt-get install -yq \
    ant \
    apg \
    autoconf \
    automake \
    bash \
    build-essential \
    cmake \
    curl \
    dos2unix \
    file \
    g++ \
    git \
    git-lfs \
    gnupg \
    libogdi-dev \
    libssl-dev \
    libtool \
    libxml2-dev \
    make \
    ninja-build \
    patch \
    python3-pip \
    sqlite3 \
    swig \
    tcl \
    wget \
    zip \
    zlib1g-dev

RUN curl https://packages.adoptium.net/artifactory/api/gpg/key/public | apt-key add - \
    && echo "deb https://packages.adoptium.net/artifactory/deb $(awk -F= '/^VERSION_CODENAME/{print$2}' /etc/os-release) main" | tee /etc/apt/sources.list.d/adoptium.list \
    && apt-get update \
    && apt-get install -yq temurin-8-jdk
ENV JAVA_HOME=/usr/lib/jvm/temurin-8-jdk-amd64
RUN update-alternatives --set java $JAVA_HOME/bin/java

WORKDIR /

RUN pip install conan \
    && conan profile new default --detect \
    && conan profile update settings.compiler.version=8 default

ENV ANDROID_SDK_ROOT=/Android/sdk
RUN mkdir -p $ANDROID_SDK_ROOT

RUN wget -q https://cmake.org/files/v3.14/cmake-3.14.7-Linux-x86_64.tar.gz \
    && tar xfz cmake-3.14.7-Linux-x86_64.tar.gz \
    && mkdir -p $ANDROID_SDK_ROOT/cmake \
    && mv cmake-3.14.7-Linux-x86_64 $ANDROID_SDK_ROOT/cmake/3.14.7
ENV CMAKE_VERSION=3.14.7 \
    CMAKE_DIR=$ANDROID_SDK_ROOT/cmake/3.14.7
ENV PATH=$PATH:$CMAKE_DIR/bin

RUN wget -q https://dl.google.com/android/repository/android-ndk-r12b-linux-x86_64.zip \
    && unzip -q android-ndk-r12b-linux-x86_64.zip \
    && mv android-ndk-r12b $ANDROID_SDK_ROOT/ndk
ENV ANDROID_NDK=$ANDROID_SDK_ROOT/ndk \
    ANDROID_NDK_HOME=$ANDROID_SDK_ROOT/ndk

RUN wget -q https://dl.google.com/android/repository/commandlinetools-linux-9123335_latest.zip \
    && unzip -q commandlinetools-linux-9123335_latest.zip \
    && mkdir -p $ANDROID_SDK_ROOT/cmdline-tools \
    && mv cmdline-tools $ANDROID_SDK_ROOT/cmdline-tools/8.0

RUN yes | $ANDROID_SDK_ROOT/cmdline-tools/8.0/bin/sdkmanager --sdk_root=${ANDROID_SDK_ROOT} --licenses
RUN yes | $ANDROID_SDK_ROOT/cmdline-tools/8.0/bin/sdkmanager --sdk_root=${ANDROID_SDK_ROOT} --install "platforms;android-29"

RUN git lfs clone --depth 1 https://github.com/deptofdefense/AndroidTacticalAssaultKit-CIV
WORKDIR /AndroidTacticalAssaultKit-CIV
RUN git submodule update --init --recursive
ADD local.properties atak

RUN scripts/prebuild.sh

RUN keytool -keystore my-debug-key.keystore -genkey -noprompt -keyalg RSA -alias debug -dname "CN=Unknown, OU=Unknown, O=MyOrganization, L=MyCity, ST=MyState, C=US" -storepass atakatak -keypass atakatak \
    && keytool -keystore my-release-key.keystore -genkey -noprompt -keyalg RSA -alias release -dname "CN=Unknown, OU=Unknown, O=MyOrganization, L=MyCity, ST=MyState, C=US" -storepass atakatak -keypass atakatak \
    && mkdir -p atak/ATAK/app \
    && cp my-debug-key.keystore my-release-key.keystore atak/ATAK/app

WORKDIR /AndroidTacticalAssaultKit-CIV/atak
# HACK HACK run this twice, ignoring the first error.
RUN ./gradlew --stacktrace assembleCivDebug || true
RUN ./gradlew --stacktrace assembleCivDebug
