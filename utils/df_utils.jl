using Dates
using TimeZones




function date2datetime(dt::AbstractString; timezone=tz"UTC")
    df = dateformat"yyyy-mm-dd HH:MM:SS.sss"
    df2 = dateformat"yyyy-mm-dd HH:MM:SS"

    dt_string = strip(String(dt))
    dt_split = split(dt_string, ".")

    if length(dt_split) > 1
        dt_out = join([dt_split[1], dt_split[2][1:end-3]], ".")
        zdt = ZonedDateTime(DateTime(dt_out, df), timezone)
    else
        dt_out = dt_split[1]
        zdt = ZonedDateTime(DateTime(dt_out, df2), timezone)
    end

    return zdt
end



function add_datetime_to_df!(df)
    dts = Vector{ZonedDateTime}(undef, nrow(df))

    is_row_ok = [true for _ ∈ 1:nrow(df)]
    bad_counter = 1
    for i ∈ 1:nrow(df)
        try
            dts[i] = date2datetime(df.dateTime[i])
        catch e
            is_row_ok[i] = false
            dts[i] = ZonedDateTime(2000, 1, 1, 1, tz"UTC")
            if bad_counter ≤ 1
                println(e)
            end
            bad_counter += 1
        end
    end


    # drop bad rows

    if sum(is_row_ok) != nrow(df)
        println("\t% of bad rows: ", 100.0*(nrow(df) - sum(is_row_ok))/nrow(df))
        idx_good = findfirst(x->x==true, is_row_ok)
        idx_bad = findfirst(x->x==false, is_row_ok)
        println("\t\tfirst good row: ", df.dateTime[idx_good])
        println("\t\tfirst bad row: ", df.dateTime[idx_bad])
    end

    df.dateTime .= dts
    df = df[is_row_ok, :]
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




col_types_ips = Dict(
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
    "date"          => Date,
    "date_and_hour" => DateTime,
)

col_types_bme = Dict(
    "dateTime"      => String,
    "temperature"   => Float64,
    "pressure"      => Float64,
    "humidity"      => Float64,
    "gas"           => Float64,
    "date_and_hour" => DateTime,
)
