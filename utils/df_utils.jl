# data sheets for inst uncertainty:
# ips7100: https://pierasystems.com/wp-content/uploads/2023/09/IPS-Datasheet-V1.3.7.pdf
# bme280: https://www.mouser.com/datasheet/2/783/BST-BME280-DS002-1509607.pdf
# bme680: https://www.mouser.com/datasheet/2/783/BST_BME680_DS001-1509608.pdf



ips_types = Dict(
    "dateTime"      => String,
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
    "dateTime"      => String,
    "temperature"   => Float64,
    "pressure"      => Float64,
    "humidity"      => Float64,
    "altitude"      => Float64,
)

bme680_types = Dict(
    "dateTime"      => String,
    "temperature"   => Float64,
    "pressure"      => Float64,
    "humidity"      => Float64,
    "gas"      => Float64,
)




function parse_datetime(dt::String)
    # split into Date and Time
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
end

function parse_datetime!(df::DataFrame)
    df.dateTime = parse_datetime.(df.dateTime)
end







function window_idxs(i, N, Z::AbstractVector)
    if N > length(Z)
        thow(ArgumentError("N must be less than length of data"))
    end

    n = Int((N-1)/2)

    idx_out = i-n:i+n

    # handle edge cases
    if idx_out[1] < 1
        offset = 1-idx_out[1]
        idx_out = idx_out .+ offset
    end

    if idx_out[end] > length(Z)
        offset = idx_out[end] - length(Z)
        idx_out = idx_out .- offset
    end

    return idx_out
end


function mean_dev(Z::AbstractVector)
    μ = mean(Z)
    return sum(abs.(Z .- μ))/length(Z)
end



