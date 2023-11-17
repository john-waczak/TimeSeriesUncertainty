# data sheets for inst uncertainty:
# ips7100: https://pierasystems.com/wp-content/uploads/2023/09/IPS-Datasheet-V1.3.7.pdf
# bme280: https://www.mouser.com/datasheet/2/783/BST-BME280-DS002-1509607.pdf
# bme680: https://www.mouser.com/datasheet/2/783/BST_BME680_DS001-1509608.pdf


# 1 Hz for IPS7100 and 0.1 Hz for BME680, BME280
# df_ips.dateTime = round.(df_ips.dateTime, Second(1))
# df_bme280.dateTime = round.(df_bme280.dateTime, Second(10))
# df_bme680.dateTime = round.(df_bme680.dateTime, Second(10))



using DataInterpolations

ips_types = Dict(
#    "dateTime"      => String,
    "pc0_1"         => Int,
    "pc0_3"         => Int,
    "pc0_5"         => Int,
    "pc1_0"         => Int,
    "pc2_5"         => Int,
    "pc5_0"         => Int,
    "pc10_0"        => Int,
    "pm0_1"         => Float64,
    "pm0_3"         => Float64,
    "pm0_5"         => Float64,
    "pm1_0"         => Float64,
    "pm2_5"         => Float64,
    "pm5_0"         => Float64,
    "pm10_0"        => Float64,
)

bme280_types = Dict(
    # "dateTime"      => String,
    "temperature"   => Float64,
    "pressure"      => Float64,
    "humidity"      => Float64,
    "altitude"      => Float64,
)

bme680_types = Dict(
    # "dateTime"      => String,
    "temperature"   => Float64,
    "pressure"      => Float64,
    "humidity"      => Float64,
    "gas"      => Float64,
)


ips_columns = [
    :dateTime,
    :pc0_1,
    :pc0_3,
    :pc0_5,
    :pc1_0,
    :pc2_5,
    :pc5_0,
    :pc10_0,
    :pm0_1,
    :pm0_3,
    :pm0_5,
    :pm1_0,
    :pm2_5,
    :pm5_0,
    :pm10_0,
]

bme280_columns = [
    :dateTime,
    :pressure,
    :temperature,
    :humidity,
]

bme680_columns = [
    :dateTime,
    :pressure,
    :temperature,
    :humidity,
]




function parse_datetime(dt)
    # split into Date and Time
    try
        ymd, hms = split(dt, " ")

        # split Date into year,month, day
        y,m,d = parse.(Int, split(ymd, "-"))

        # split Time into hour, minute, second
        h,min,s = split(hms, ":")
        h = parse(Int, h)
        min = parse(Int, min)

        # get seconds and milliseconds
        s = parse(Float64, s)
        s = round(s, digits=3)

        # handle edge case
        if s == 60.000
            s = 59.999
        end

        s,milli = parse.(Int, split("$(s)", "."))

        return DateTime(y,m,d,h,min,s,milli)
    catch e
        return missing
    end
end



function parse_datetime!(df::DataFrame)
    ts_new = Union{Missing, DateTime}[parse_datetime(t) for t ∈ df.dateTime]
    df.dateTime = ts_new
end



function process_ips7100(df)
    Δt = 1.0 # 1 Hz sample frequency

    t_start = round(df.dateTime[1], Second(1), RoundUp)
    ts = [t.value ./ 1000 for t ∈ df.dateTime .- t_start]
    t_end = round(ts[end], RoundDown)

    df_out = DataFrame()
    df_out.datetime = t_start .+ Second.(0.0:Δt:t_end)


    for j ∈ 2:ncol(df)
        colname = names(df)[j]
        Z = Float64.(df[!,j])
        #itp = CubicSpline(Z, ts)
        itp = LinearInterpolation(Z, ts)

        Zout = itp(0.0:Δt:t_end)

        if occursin("pc", colname)
            Zout = round.(Int, Zout)
        end


        df_out[!, colname] = Zout
    end

    df_out.datetime_quarterhour = round.(df_out.datetime, Minute(15))

    return df_out
end


function process_bme280(df)
    Δt = 10.0 # 0.1 Hz sample frequency

    t_start = round(df.dateTime[1], Second(10), RoundUp)
    ts = [t.value ./ 1000 for t ∈ df.dateTime .- t_start]
    t_end = (round(df.dateTime[end], Second(10), RoundDown) - t_start).value / 1000


    df_out = DataFrame()
    df_out.datetime = t_start .+ Second.(0.0:Δt:t_end)

    names(df)

    for j ∈ 2:ncol(df)
        colname = names(df)[j]
        Z = Float64.(df[!,j])

        itp = LinearInterpolation(Z, ts)

        Zout = itp(0.0:Δt:t_end)

        df_out[!, colname] = Zout
    end

    df_out.datetime_quarterhour = round.(df_out.datetime, Minute(15))

    return df_out
end


function process_bme680(df)
    Δt = 10.0 # 0.1 Hz sample frequency

    t_start = round(df.dateTime[1], Second(10), RoundUp)
    ts = [t.value ./ 1000 for t ∈ df.dateTime .- t_start]
    t_end = (round(df.dateTime[end], Second(10), RoundDown) - t_start).value / 1000


    df_out = DataFrame()
    df_out.datetime = t_start .+ Second.(0.0:Δt:t_end)

    names(df)

    for j ∈ 2:ncol(df)
        colname = names(df)[j]
        Z = Float64.(df[!,j])

        itp = LinearInterpolation(Z, ts)

        Zout = itp(0.0:Δt:t_end)

        df_out[!, colname] = Zout
    end

    df_out.datetime_quarterhour = round.(df_out.datetime, Minute(15))

    return df_out
end






Δ_pc0_1(x) = (x > 200_000) ? round(Int, 0.1*x) : 20_000
Δ_pc0_3(x) = Δ_pc0_1(x)
Δ_pc0_5(x) = Δ_pc0_1(x)
Δ_pc1_0(x) = Δ_pc0_1(x)
Δ_pc2_5(x) = Δ_pc0_1(x)
Δ_pc5_0(x) = (x > 1_000_000) ? round(Int, 0.1*x) : 100_000
Δ_pc10_0(x) = Δ_pc5_0(x)


Δ_pm0_1(x) = (x > 50.0) ? 0.1*x : 5.0
Δ_pm0_3(x) = Δ_pm0_1(x)
Δ_pm0_5(x) = Δ_pm0_1(x)
Δ_pm1_0(x) = Δ_pm0_1(x)
Δ_pm2_5(x) = Δ_pm0_1(x)
Δ_pm5_0(x) = (x > 50.0) ? 0.2*x : 10.0
Δ_pm10_0(x) = Δ_pm5_0(x)


function add_ips_uncertainty!(df)
    # add uncertainty for particle counts
    df.pc0_1__unc_inst = Δ_pc0_1.(df.pc0_1)
    df.pc0_3__unc_inst = Δ_pc0_3.(df.pc0_3)
    df.pc0_5__unc_inst = Δ_pc0_5.(df.pc0_5)
    df.pc1_0__unc_inst = Δ_pc1_0.(df.pc1_0)
    df.pc2_5__unc_inst = Δ_pc2_5.(df.pc2_5)
    df.pc5_0__unc_inst = Δ_pc5_0.(df.pc5_0)
    df.pc10_0__unc_inst = Δ_pc10_0.(df.pc10_0)

    # add uncertainty for particulate matter
    df.pm0_1__unc_inst = Δ_pm0_1.(df.pm0_1)
    df.pm0_3__unc_inst = Δ_pm0_3.(df.pm0_3)
    df.pm0_5__unc_inst = Δ_pm0_5.(df.pm0_5)
    df.pm1_0__unc_inst = Δ_pm1_0.(df.pm1_0)
    df.pm2_5__unc_inst = Δ_pm2_5.(df.pm2_5)
    df.pm5_0__unc_inst = Δ_pm5_0.(df.pm5_0)
    df.pm10_0__unc_inst = Δ_pm10_0.(df.pm10_0)
end




function add_bme280_uncertainty!(df)
    df.temperature__unc_inst = zeros(nrow(df))
    df.pressure__unc_inst = zeros(nrow(df))
    df.humidity__unc_inst = 0.03 .* df.humidity

    Threads.@threads for row ∈ eachrow(df)

        # pressure uncertainty
        if row.pressure < 1100
            if row.temperature > -20.0 && row.temperature < 0.0
                row.pressure__unc_inst = 1.7
            else
                row.pressure__unc_inst = 1.0
            end
        else
            row.pressure__unc_inst = 1.5
        end

        # temperature uncertainty
        if row.temperature < -20.0
            row.temperature__unc_inst = 1.5
        elseif row.temperature < 0.0
            row.temperature__unc_inst = 1.25
        else
            row.temperature__unc_inst = 1.0
        end
    end
end



function add_bme680_uncertainty!(df)
    df.temperature__unc_inst = 1.0 .* ones(nrow(df))
    df.pressure__unc_inst = 0.6 .* ones(nrow(df))
    df.humidity__unc_inst = 0.03 .* df.humidity
end


